"""Black-box tests for `make install` in the agent-generator repo.

Contracts under test (observable behavior only):
  1. Every setup/agent-setup/agents/*.md template is processed into
     output/agents/<same-name>.md.
  2. The frontmatter `shared:` key and only its list items are removed;
     all other frontmatter keys/values are preserved verbatim.
  3. The template body is preserved verbatim.
  4. Shared fragment files (setup/agent-setup/agents-shared/*.md) named by `shared:`
     are appended to the output in declared order.
  5. Templates without a `shared:` key are copied unchanged (byte for byte).
  6. setup/agent-setup/agents-appends/APPEND_SYSTEM.md is processed the same
     way into output/agents/APPEND_SYSTEM.md.
  7. Referencing a missing shared fragment fails `make install` (rc != 0).

   Each test builds a hermetic temporary fixture, copies the repo Makefile
   into it, and runs `make install` there. Only generated output files are
   inspected; no Makefile/source text is asserted on.

   Additional observable contracts:
   8. install replaces output/agents with the exact generated set: a
      pre-existing stale .md is removed.
   9. Once the leading frontmatter closes, body content is never
      re-parsed as frontmatter: a body containing `---`, `shared:` and
      bullet rows survives verbatim while the real shared block is
      removed/appended.
   10. Blank lines and comments inside the declared shared list do not
       stop processing: later tags still append in declared order and the
       whole shared section disappears.
   11. CRLF source frontmatter (fences/key/list) is recognized, the
       shared block removed, and fragments appended.
  12. Unsafe shared tags containing path traversal (e.g. ../outside)
      are rejected, even if the referenced escaped .md file exists,
      and an existing output/agents sentinel remains untouched.
  13. A shared fragment file that is a symlink escaping
      setup/agent-setup/agents-shared/ is rejected even though its tag name passes
      lexical validation, and an existing output/agents sentinel
      remains untouched.
  14. When the source body's final line lacks a trailing newline, the
      generated result is the source with the shared section removed
      byte-for-byte followed immediately by the exact fragment bytes
      — no invented newline at the seam or end of file.
  15. output/agents is created with permissions consistent with a
      normal `mkdir -p` under the ambient umask: group and others can
      read and traverse the directory (r-x for group and other).
"""

import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent

ALPHA = "ALPHA_FRAGMENT_MARKER\n"
BETA = "BETA_FRAGMENT_MARKER\n"


def _template(shared_lines):
    """A minimal agent template with a `shared:` block of the given lines."""
    return (
        "---\n"
        "name: fixture-agent\n"
        'description: "fixture desc"\n'
        "tools: \n"
        "  - read\n"
        "  - write\n"
        "shared: \n"
        + "".join(shared_lines)
        + "model: \n"
        "  - fmodel\n"
        "---\n"
        "BODY_LINE_ONE\n"
        "BODY_LINE_TWO\n"
    )


def _find_make():
    for name in ("make", "gmake"):
        path = shutil.which(name)
        if path:
            return path
    raise unittest.SkipTest("no make (or gmake) found on PATH")


class MakeInstallTestCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory(prefix="agent-gen-")
        self.root = Path(self._tmp.name)
        shutil.copy(REPO_ROOT / "Makefile", self.root / "Makefile")

    def tearDown(self):
        self._tmp.cleanup()

    def write(self, relpath, content):
        path = self.root / relpath
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def run_install(self):
        env = dict(os.environ)
        for var in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL"):
            env.pop(var, None)
        return subprocess.run(
            [_find_make(), "install"],
            cwd=self.root,
            env=env,
            capture_output=True,
            text=True,
        )

    def output_path(self, name):
        return self.root / "output" / "agents" / name

    @staticmethod
    def frontmatter(text):
        """Return the text between the leading --- fences, or None."""
        if not text.startswith("---"):
            return None
        parts = text.split("---", 2)
        if len(parts) < 3:
            return None
        return parts[1]

    # --- contract: shared key + its items removed, rest preserved -------

    def test_removes_shared_key_and_its_items_only(self):
        self.write("setup/agent-setup/agents/fixture.md",
                   _template(["  - alpha\n", "  - beta\n"]))
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        self.write("setup/agent-setup/agents-shared/beta.md", BETA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out = self.output_path("fixture.md")
        self.assertTrue(out.exists(), "output/agents/fixture.md not created")
        text = out.read_text(encoding="utf-8")
        fm = self.frontmatter(text)
        self.assertIsNotNone(fm)

        # other frontmatter keys/values preserved
        self.assertIn("name: fixture-agent", fm)
        self.assertIn("fixture desc", fm)
        self.assertIn("- read", fm)  # tools list item survives
        self.assertIn("- write", fm)
        self.assertIn("- fmodel", fm)

        # shared key and its list items removed
        self.assertNotIn("shared:", fm)
        self.assertNotIn("- alpha", fm)
        self.assertNotIn("- beta", fm)

        # body preserved verbatim
        self.assertIn("BODY_LINE_ONE\nBODY_LINE_TWO", text)

        # fragments appended at the end, in declared order
        self.assertIn("ALPHA_FRAGMENT_MARKER", text)
        self.assertIn("BETA_FRAGMENT_MARKER", text)
        self.assertLess(text.index("BODY_LINE_TWO"),
                        text.index("ALPHA_FRAGMENT_MARKER"))
        self.assertLess(text.index("ALPHA_FRAGMENT_MARKER"),
                        text.index("BETA_FRAGMENT_MARKER"))
        self.assertTrue(text.rstrip().endswith(BETA.rstrip()))

    # --- contract: fragments appended in declared order -----------------

    def _run_order_case(self, shared_lines, first, second):
        self.write("setup/agent-setup/agents/fixture.md", _template(shared_lines))
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        self.write("setup/agent-setup/agents-shared/beta.md", BETA)
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        text = self.output_path("fixture.md").read_text(encoding="utf-8")
        self.assertIn(first, text)
        self.assertIn(second, text)
        self.assertLess(text.index(first), text.index(second))
        self.assertTrue(text.rstrip().endswith(second.rstrip()))

    def test_fragments_appended_in_declared_order(self):
        self._run_order_case(["  - alpha\n", "  - beta\n"], ALPHA, BETA)

    def test_fragments_appended_in_reverse_declared_order(self):
        self._run_order_case(["  - beta\n", "  - alpha\n"], BETA, ALPHA)

    def test_shared_removal_does_not_touch_other_lists_sharing_a_name(self):
        # A tool name collides with a declared shared fragment. Removal of the
        # `shared:` key and its list items must NOT remove the same item from an
        # unrelated frontmatter list (tools), and the fragment still appends.
        template = (
            "---\n"
            "name: collision\n"
            "tools: \n"
            "  - alpha\n"
            "  - read\n"
            "shared: \n"
            "  - alpha\n"
            "  - beta\n"
            "---\n"
            "BODY_LINE\n"
        )
        self.write("setup/agent-setup/agents/collision.md", template)
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        self.write("setup/agent-setup/agents-shared/beta.md", BETA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out = self.output_path("collision.md")
        self.assertTrue(out.exists(), "output/agents/collision.md not created")
        text = out.read_text(encoding="utf-8")
        fm = self.frontmatter(text)
        self.assertIsNotNone(fm)

        # tools list item with the same name as a shared fragment survives
        self.assertIn("- alpha", fm)
        self.assertIn("- read", fm)
        # shared key and its list items removed
        self.assertNotIn("shared:", fm)
        # body preserved verbatim
        self.assertIn("BODY_LINE", text)
        # fragment appended, in declared order, after the body
        self.assertIn("ALPHA_FRAGMENT_MARKER", text)
        self.assertIn("BETA_FRAGMENT_MARKER", text)
        self.assertLess(text.index("BODY_LINE"),
                        text.index("ALPHA_FRAGMENT_MARKER"))
        self.assertLess(text.index("ALPHA_FRAGMENT_MARKER"),
                        text.index("BETA_FRAGMENT_MARKER"))
        self.assertTrue(text.rstrip().endswith(BETA.rstrip()))

    # --- contract: templates without shared stay unchanged ---------------

    def test_template_without_shared_unchanged(self):
        template = (
            "---\n"
            "name: plain\n"
            "description: plain agent\n"
            "---\n"
            "BODY_ONE\n"
            "BODY_TWO\n"
        )
        self.write("setup/agent-setup/agents/plain.md", template)
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        out = self.output_path("plain.md")
        self.assertTrue(out.exists(), "output/agents/plain.md not created")
        self.assertEqual(out.read_text(encoding="utf-8"), template)

    def test_no_shared_key_ignores_fragment_name_collision(self):
        # No `shared:` key, but an unrelated frontmatter list item happens to
        # name an existing shared fragment file. `make install` must NOT infer
        # a shared dependency from it: the template must pass through
        # byte-for-byte unchanged.
        template = (
            "---\n"
            "name: lookup\n"
            "tools: \n"
            "  - alpha\n"
            "  - read\n"
            "---\n"
            "BODY\n"
        )
        self.write("setup/agent-setup/agents/lookup.md", template)
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        out = self.output_path("lookup.md")
        self.assertTrue(out.exists(), "output/agents/lookup.md not created")
        self.assertEqual(out.read_text(encoding="utf-8"), template)

    # --- contract: APPEND_SYSTEM.md processed the same way ---------------

    def test_append_system_processed_like_agent(self):
        self.write(
            "setup/agent-setup/agents-appends/APPEND_SYSTEM.md",
            "---\n"
            "shared: \n"
            "  - alpha\n"
            "  - beta\n"
            "---\n",
        )
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        self.write("setup/agent-setup/agents-shared/beta.md", BETA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out = self.output_path("APPEND_SYSTEM.md")
        self.assertTrue(out.exists(), "output/agents/APPEND_SYSTEM.md not created")
        text = out.read_text(encoding="utf-8")
        fm = self.frontmatter(text)
        self.assertIsNotNone(fm)
        self.assertNotIn("shared:", fm)
        self.assertNotIn("- alpha", fm)
        self.assertNotIn("- beta", fm)
        self.assertIn("ALPHA_FRAGMENT_MARKER", text)
        self.assertIn("BETA_FRAGMENT_MARKER", text)
        self.assertLess(text.index("ALPHA_FRAGMENT_MARKER"),
                        text.index("BETA_FRAGMENT_MARKER"))

    # --- contract: every real template is processed -----------------------

    def test_every_real_template_processed_into_output(self):
        for rel in ("setup/agent-setup/agents", "setup/agent-setup/agents-appends",
                    "setup/agent-setup/agents-shared"):
            shutil.copytree(REPO_ROOT / rel, self.root / rel)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out_dir = self.root / "output" / "agents"
        self.assertTrue(out_dir.is_dir(), "output/agents/ not created")
        expected = {p.name for p in (self.root / "setup/agent-setup/agents").glob("*.md")}
        expected.add("APPEND_SYSTEM.md")
        produced = {p.name for p in out_dir.glob("*.md")}
        self.assertEqual(produced, expected)

        for p in out_dir.glob("*.md"):
            fm = self.frontmatter(p.read_text(encoding="utf-8"))
            self.assertIsNotNone(fm, f"{p.name} has no frontmatter")
            self.assertNotIn("shared:", fm, f"{p.name} still declares shared:")

    # --- contract: missing shared fragment fails --------------------------

    def test_missing_shared_file_fails_install(self):
        self.write(
            "setup/agent-setup/agents/broken.md",
            "---\n"
            "name: broken\n"
            "shared: \n"
            "  - does-not-exist\n"
            "---\n"
            "BODY\n",
        )
        result = self.run_install()
        self.assertNotEqual(
            result.returncode, 0,
            "make install must fail when a declared shared fragment is missing",
        )

    # --- contract: install replaces the generated set exactly ------------

    def test_install_removes_stale_output_file(self):
        self.write("setup/agent-setup/agents/fixture.md",
                   _template(["  - alpha\n"]))
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        # stale artifact from a previous run; install must not leave it behind
        stale = self.output_path("stale.md")
        stale.parent.mkdir(parents=True, exist_ok=True)
        stale.write_text("STALE CONTENT\n", encoding="utf-8")

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        self.assertFalse(stale.exists(),
                         "stale output/agents/stale.md must be removed")
        produced = {p.name for p in (self.root / "output" / "agents").glob("*.md")}
        self.assertEqual(produced, {"fixture.md"})

    # --- contract: body is never re-parsed as frontmatter ----------------

    def test_body_shared_like_content_is_not_treated_as_frontmatter(self):
        template = (
            "---\n"
            "name: tricky\n"
            "shared: \n"
            "  - alpha\n"
            "---\n"
            "BODY_START\n"
            "---\n"
            "BODY_AFTER_FENCE\n"
            "shared: \n"
            "  - not-a-fragment\n"
            "- top-level-bullet\n"
            "BODY_END\n"
        )
        self.write("setup/agent-setup/agents/tricky.md", template)
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out = self.output_path("tricky.md")
        self.assertTrue(out.exists(), "output/agents/tricky.md not created")
        text = out.read_text(encoding="utf-8")
        fm = self.frontmatter(text)
        self.assertIsNotNone(fm)

        # the *frontmatter* shared block is removed
        self.assertNotIn("shared:", fm)
        self.assertNotIn("- alpha", fm)
        # the *body* block, including its own fence, `shared:` key and
        # bullet rows, survives verbatim
        self.assertIn(
            "BODY_START\n---\nBODY_AFTER_FENCE\nshared: \n"
            "  - not-a-fragment\n- top-level-bullet\nBODY_END",
            text,
        )
        # fragment appended after the body, not inside it
        self.assertIn(ALPHA, text)
        self.assertLess(text.index("BODY_END"), text.index(ALPHA))

    # --- contract: blanks/comments in the shared list don't stop it -------

    def test_blank_lines_and_comments_in_shared_list_keep_processing(self):
        template = (
            "---\n"
            "name: spaced\n"
            "shared: \n"
            "  - alpha\n"
            "\n"
            "  # a comment inside the shared block\n"
            "  - beta\n"
            "model: \n"
            "  - fmodel\n"
            "---\n"
            "BODY_LINE\n"
        )
        self.write("setup/agent-setup/agents/spaced.md", template)
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        self.write("setup/agent-setup/agents-shared/beta.md", BETA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out = self.output_path("spaced.md")
        self.assertTrue(out.exists(), "output/agents/spaced.md not created")
        text = out.read_text(encoding="utf-8")
        fm = self.frontmatter(text)
        self.assertIsNotNone(fm)
        self.assertNotIn("shared:", fm)

        # whole shared section disappears: items, blank line and comment
        self.assertNotIn("- alpha", fm)
        self.assertNotIn("- beta", text)
        self.assertNotIn("# a comment inside the shared block", text)
        # unrelated frontmatter preserved
        self.assertIn("- fmodel", fm)
        # both fragments appended, in declared order, after the body
        self.assertIn(ALPHA, text)
        self.assertIn(BETA, text)
        self.assertLess(text.index("BODY_LINE"), text.index(ALPHA))
        self.assertLess(text.index(ALPHA), text.index(BETA))
        self.assertTrue(text.rstrip().endswith(BETA.rstrip()))

    # --- contract: CRLF sources processed like LF ones --------------------

    def test_crlf_source_shared_removed_and_fragment_appended(self):
        template = (
            "---\r\n"
            "name: crlf\r\n"
            "shared: \r\n"
            "  - alpha\r\n"
            "  - beta\r\n"
            "---\r\n"
            "BODY_LINE\r\n"
        )
        src = self.root / "setup/agent-setup/agents/crlf.md"
        src.parent.mkdir(parents=True, exist_ok=True)
        src.write_bytes(template.encode("utf-8"))
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)
        self.write("setup/agent-setup/agents-shared/beta.md", BETA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        out = self.output_path("crlf.md")
        self.assertTrue(out.exists(), "output/agents/crlf.md not created")
        # processed, not copied through unchanged
        self.assertNotEqual(out.read_bytes(), template.encode("utf-8"))
        text = out.read_text(encoding="utf-8")
        fm = self.frontmatter(text)
        self.assertIsNotNone(fm)
        self.assertNotIn("shared:", fm)
        self.assertNotIn("- alpha", fm)
        self.assertNotIn("- beta", fm)
        # body survives; fragments appended in declared order after it
        self.assertIn("BODY_LINE", text)
        self.assertIn(ALPHA, text)
        self.assertIn(BETA, text)
        self.assertLess(text.index("BODY_LINE"), text.index(ALPHA))
        self.assertLess(text.index(ALPHA), text.index(BETA))
        self.assertTrue(text.rstrip().endswith(BETA.rstrip()))


    # --- contract: unsafe shared tag with path traversal is rejected ------

    def test_unsafe_shared_tag_with_path_traversal_fails(self):
        # A shared tag containing path traversal (e.g. ../outside) must
        # fail install even when the escaped file exists, and must leave
        # any existing output/agents contents untouched.
        self.write(
            "setup/agent-setup/agents/traversal.md",
            "---\n"
            "name: traversal\n"
            "shared: \n"
            "  - ../outside\n"
            "---\n"
            "BODY\n",
        )
        # The tag resolves to setup/agent-setup/agents-shared/../outside.md, i.e.
        # setup/agent-setup/outside.md — make both the directory and the file
        # exist so the plain -f check passes and path resolution works.
        self.write("setup/agent-setup/agents-shared/.keep", "")
        self.write("setup/agent-setup/outside.md", "ESCAPED\n")

        sent = self.output_path("sentinel.md")
        sent.parent.mkdir(parents=True, exist_ok=True)
        sent.write_text("SENTINEL\n", encoding="utf-8")

        result = self.run_install()
        self.assertNotEqual(
            result.returncode, 0,
            "make install must reject a shared tag with path traversal",
        )
        # Sentinel must survive the failed install unchanged.
        self.assertTrue(sent.exists(),
                        "output/agents sentinel must not be removed on failure")
        self.assertEqual(sent.read_text(encoding="utf-8"), "SENTINEL\n")

    # --- contract: shared fragment symlink escaping shared dir rejected --

    def test_shared_symlink_escaping_shared_dir_fails(self):
        # A shared tag whose name passes lexical validation (`leak`) but
        # whose fragment file is a symlink pointing outside
        # setup/agent-setup/agents-shared/ must fail install and must leave an existing
        # output/agents sentinel untouched.
        self.write(
            "setup/agent-setup/agents/leaker.md",
            "---\n"
            "name: leaker\n"
            "shared: \n"
            "  - leak\n"
            "---\n"
            "BODY\n",
        )
        # The symlink resolves outside setup/agent-setup/agents-shared/.  Make the target
        # exist so a plain -f check (which follows symlinks) would pass.
        self.write("setup/agent-setup/outside.md", "LEAKED\n")

        link = self.root / "setup/agent-setup/agents-shared" / "leak.md"
        link.parent.mkdir(parents=True, exist_ok=True)
        os.symlink("../outside.md", link)

        sent = self.output_path("sentinel.md")
        sent.parent.mkdir(parents=True, exist_ok=True)
        sent.write_text("SENTINEL\n", encoding="utf-8")

        result = self.run_install()
        self.assertNotEqual(
            result.returncode, 0,
            "make install must reject a shared fragment that is a symlink "
            "escaping the shared directory",
        )
        # Sentinel must survive the failed install unchanged.
        self.assertTrue(sent.exists(),
                        "output/agents sentinel must not be removed on failure")
        self.assertEqual(sent.read_text(encoding="utf-8"), "SENTINEL\n")

    # --- contract: no invented newline when source lacks trailing NL -----

    def test_no_invented_newline_at_source_end_before_fragment(self):
        # When the source body's last line has no trailing newline and
        # an explicit shared block is present, the output must be exactly:
        #   source-with-shared-removed-byte-for-byte + fragment-bytes
        # with NO invented newline at the seam or end of file.
        fragment = b"ALPHA_FRAGMENT_MARKER\n"
        src = (
            b"---\n"
            b"name: tight\n"
            b"shared: \n"
            b"  - alpha\n"
            b"---\n"
            b"BODY_LAST_NO_NL"
            # intentionally no trailing newline
        )

        src_path = self.root / "setup/agent-setup/agents" / "tight.md"
        src_path.parent.mkdir(parents=True, exist_ok=True)
        src_path.write_bytes(src)

        frag_path = self.root / "setup/agent-setup" / "agents-shared" / "alpha.md"
        frag_path.parent.mkdir(parents=True, exist_ok=True)
        frag_path.write_bytes(fragment)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        # "shared: \n  - alpha\n" removed byte-for-byte from the source,
        # then the raw fragment bytes appended immediately.
        shared_section = b"shared: \n  - alpha\n"
        expected = src.replace(shared_section, b"") + fragment

        out = self.output_path("tight.md")
        self.assertTrue(out.exists(), "output/agents/tight.md not created")
        self.assertEqual(out.read_bytes(), expected,
                         "must not invent a newline at the fragment seam")

    # --- contract: output/agents is group/other traversable ----------------

    def test_output_agents_permissions_match_normal_mkdir(self):
        # output/agents must be created with permissions consistent with
        # a normal `mkdir -p` under the ambient umask: group and others
        # can read and traverse the directory.
        self.write("setup/agent-setup/agents/fixture.md",
                   _template(["  - alpha\n"]))
        self.write("setup/agent-setup/agents-shared/alpha.md", ALPHA)

        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        agents = self.root / "output" / "agents"
        self.assertTrue(agents.is_dir(), "output/agents/ not created")
        mode = stat.S_IMODE(agents.stat().st_mode)

        # A `mkdir -p` under common umask (022) yields 0o755;
        # group and others must have read + traverse (0o055).
        self.assertEqual(
            mode & 0o055, 0o055,
            "output/agents/ must be readable and traversable by group/others",
        )


if __name__ == "__main__":
    unittest.main()
