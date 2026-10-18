# Wrangler Command Reference

Complete CLI command reference by product. For config/binding shapes see [configuration.md](./configuration.md); for workflows see [patterns.md](./patterns.md).

Your knowledge of Wrangler CLI flags and subcommands may be outdated. **Prefer retrieval over pre-training**: check `https://developers.cloudflare.com/workers/wrangler/` and `node_modules/wrangler/config-schema.json` before writing or reviewing commands.

## Key Guidelines

- **Use `wrangler.jsonc`**: Prefer JSON config over TOML. Newer features are JSON-only.
- **Set `compatibility_date`**: Use a recent date (within 30 days). Check https://developers.cloudflare.com/workers/configuration/compatibility-dates/
- **Generate types after config changes**: Run `wrangler types` to update TypeScript bindings.
- **Local dev defaults to local storage**: Bindings use local simulation unless `remote: true`.
- **Profile Worker startup**: Run `wrangler check startup` to measure startup time and detect scripts that exceed the startup time limit.
- **Use environments for staging/prod**: Define `env.staging` and `env.production` in config.

## Quick Start: New Worker

```bash
# Initialize new project
npx wrangler init my-worker

# Or with a framework
npx create-cloudflare@latest my-app
```

## Core Commands

| Task | Command |
|------|---------|
| Start local dev server | `wrangler dev` |
| Deploy to Cloudflare | `wrangler deploy` |
| Deploy dry run | `wrangler deploy --dry-run` |
| Generate TypeScript types | `wrangler types` |
| Profile Worker startup time | `wrangler check startup` |
| View live logs | `wrangler tail` |
| Delete Worker | `wrangler delete` |
| Auth status | `wrangler whoami` |

## Types

```bash
# Generate worker-configuration.d.ts
wrangler types

# Custom output path
wrangler types ./src/env.d.ts

# Check types are up to date (CI)
wrangler types --check
```

## Local Development

```bash
# Local mode (default) - uses local storage simulation
wrangler dev

# With specific environment
wrangler dev --env staging

# Force local-only (disable remote bindings)
wrangler dev --local

# Remote mode - runs on Cloudflare edge (legacy)
wrangler dev --remote

# Custom port
wrangler dev --port 8787

# Live reload for HTML changes
wrangler dev --live-reload

# Test scheduled/cron handlers
wrangler dev --test-scheduled
# Then visit: http://localhost:8787/__scheduled
```

### Remote Bindings for Local Dev

Use `remote: true` in binding config to connect to real resources while running locally:

```jsonc
{
  "r2_buckets": [
    { "binding": "BUCKET", "bucket_name": "my-bucket", "remote": true }
  ],
  "ai": { "binding": "AI", "remote": true },
  "vectorize": [
    { "binding": "INDEX", "index_name": "my-index", "remote": true }
  ]
}
```

**Recommended remote bindings**: AI (required), Vectorize, Browser Rendering, mTLS, Images.

### Local Secrets

Create `.dev.vars` for local development secrets:

```
API_KEY=local-dev-key
DATABASE_URL=postgres://localhost:5432/dev
```

## Deployment

```bash
# Deploy to production
wrangler deploy

# Deploy specific environment
wrangler deploy --env staging

# Dry run (validate without deploying)
wrangler deploy --dry-run

# Keep dashboard-set variables
wrangler deploy --keep-vars

# Minify code
wrangler deploy --minify
```

### Versions and Rollback

```bash
# List recent versions
wrangler versions list

# View specific version
wrangler versions view <VERSION_ID>

# Rollback to previous version
wrangler rollback

# Rollback to specific version
wrangler rollback <VERSION_ID>
```

## Secrets

> **Security**: Never pass secret values as command arguments or pipe them via `echo`.
> Use the interactive prompt (preferred), pipe from a file, or use `secret bulk`.
> Never output, log, or hardcode secret values in commands.

```bash
# Set secret — interactive prompt (preferred, wrangler will ask for the value securely)
wrangler secret put API_KEY

# Set secret from a file (useful for PEM keys, CI environments)
wrangler secret put PRIVATE_KEY < path/to/private-key.pem

# List secrets
wrangler secret list

# Delete secret
wrangler secret delete API_KEY

# Bulk secrets from JSON file (do not commit this file to version control)
wrangler secret bulk secrets.json
```

## KV (Key-Value Store)

```bash
# Namespaces
wrangler kv namespace create MY_KV
wrangler kv namespace list
wrangler kv namespace delete --namespace-id <ID>

# Keys
wrangler kv key put --namespace-id <ID> "key" "value"
wrangler kv key put --namespace-id <ID> "key" "value" --expiration-ttl 3600
wrangler kv key get --namespace-id <ID> "key"
wrangler kv key list --namespace-id <ID>
wrangler kv key delete --namespace-id <ID> "key"

# Bulk put from JSON
wrangler kv bulk put --namespace-id <ID> data.json
```

## R2 (Object Storage)

```bash
# Buckets
wrangler r2 bucket create my-bucket
wrangler r2 bucket create my-bucket --location wnam
wrangler r2 bucket list
wrangler r2 bucket info my-bucket
wrangler r2 bucket delete my-bucket

# Objects
wrangler r2 object put my-bucket/path/file.txt --file ./local-file.txt
wrangler r2 object get my-bucket/path/file.txt
wrangler r2 object delete my-bucket/path/file.txt
```

## D1 (SQL Database)

```bash
# Databases
wrangler d1 create my-database
wrangler d1 create my-database --location wnam
wrangler d1 list
wrangler d1 info my-database
wrangler d1 delete my-database

# Execute SQL
wrangler d1 execute my-database --remote --command "SELECT * FROM users"
wrangler d1 execute my-database --remote --file ./schema.sql
wrangler d1 execute my-database --local --command "SELECT * FROM users"

# Migrations
wrangler d1 migrations create my-database create_users_table
wrangler d1 migrations list my-database --local
wrangler d1 migrations apply my-database --local
wrangler d1 migrations apply my-database --remote

# Export/backup
wrangler d1 export my-database --remote --output backup.sql
wrangler d1 export my-database --remote --output schema.sql --no-data
```

## Vectorize (Vector Database)

```bash
# Indexes
wrangler vectorize create my-index --dimensions 768 --metric cosine
wrangler vectorize create my-index --preset @cf/baai/bge-base-en-v1.5
wrangler vectorize list
wrangler vectorize get my-index
wrangler vectorize delete my-index

# Vectors
wrangler vectorize insert my-index --file vectors.ndjson
wrangler vectorize query my-index --vector "[0.1, 0.2, ...]" --top-k 10
```

## Hyperdrive (Database Accelerator)

```bash
# Create config
wrangler hyperdrive create my-hyperdrive \
  --origin-host db.example.com \
  --origin-port 5432 \
  --database my-database \
  --origin-user db-user \
  --origin-password "$DB_PASSWORD"

# Or using a connection string from an environment variable
wrangler hyperdrive create my-hyperdrive \
  --connection-string "$HYPERDRIVE_CONNECTION_STRING"

wrangler hyperdrive list
wrangler hyperdrive get <HYPERDRIVE_ID>
wrangler hyperdrive update <HYPERDRIVE_ID> --origin-password "$DB_PASSWORD"
wrangler hyperdrive delete <HYPERDRIVE_ID>
```

## Workers AI

```bash
# List available models
wrangler ai models

# List finetunes
wrangler ai finetune list
```

**Note**: Workers AI always runs remotely and incurs usage charges even in local dev.

## Queues

```bash
wrangler queues create my-queue
wrangler queues list
wrangler queues delete my-queue

# Consumers
wrangler queues consumer add my-queue my-worker
wrangler queues consumer remove my-queue my-worker
```

## Containers

```bash
# Build and push images
wrangler containers build -t my-app:latest .
wrangler containers build -t my-app:latest . --push
wrangler containers push my-app:latest

# Manage containers
wrangler containers list
wrangler containers info <CONTAINER_ID>
wrangler containers delete <CONTAINER_ID>

# Manage images
wrangler containers images list
wrangler containers images delete my-app:latest
```

### External Registries

> **Security**: Never hardcode registry credentials in commands. Use environment variables.

```bash
wrangler containers registries list

# Configure external registry (e.g., ECR)
wrangler containers registries configure <DOMAIN> \
  --aws-access-key-id "$AWS_ACCESS_KEY_ID"

# Configure DockerHub
wrangler containers registries configure <DOMAIN> \
  --dockerhub-username "$DOCKERHUB_USERNAME"

wrangler containers registries delete <DOMAIN>
```

## Workflows

```bash
wrangler workflows list
wrangler workflows describe my-workflow
wrangler workflows trigger my-workflow
wrangler workflows trigger my-workflow --params '{"key": "value"}'
wrangler workflows delete my-workflow

# Instances
wrangler workflows instances list my-workflow
wrangler workflows instances describe my-workflow <INSTANCE_ID>
wrangler workflows instances terminate my-workflow <INSTANCE_ID>
```

## Pipelines

```bash
wrangler pipelines create my-pipeline --r2 my-bucket
wrangler pipelines list
wrangler pipelines show my-pipeline
wrangler pipelines update my-pipeline --batch-max-mb 100
wrangler pipelines delete my-pipeline
```

## Secrets Store

```bash
# Stores
wrangler secrets-store store create my-store
wrangler secrets-store store list
wrangler secrets-store store delete <STORE_ID>

# Secrets in store
wrangler secrets-store secret put <STORE_ID> my-secret
wrangler secrets-store secret list <STORE_ID>
wrangler secrets-store secret get <STORE_ID> my-secret
wrangler secrets-store secret delete <STORE_ID> my-secret
```

## Pages (Frontend Deployment)

```bash
wrangler pages project create my-site
wrangler pages deploy ./dist
wrangler pages deploy ./dist --branch main
wrangler pages deployment list --project-name my-site
```

## Observability

```bash
# Stream live logs
wrangler tail
wrangler tail my-worker
wrangler tail --status error
wrangler tail --search "error"
wrangler tail --format json
```

```jsonc
{
  "observability": {
    "enabled": true,
    "head_sampling_rate": 1
  }
}
```

## Debug Commands

```bash
# Check auth status
wrangler whoami

# Profile Worker startup time
wrangler check startup

# View config schema
wrangler docs configuration
```

## Best Practices

1. **Version control `wrangler.jsonc`**: Treat as source of truth for Worker config.
2. **Use automatic provisioning**: Omit resource IDs for auto-creation on deploy.
3. **Run `wrangler types` in CI**: Add to build step to catch binding mismatches.
4. **Use environments**: Separate staging/production with `env.staging`, `env.production`.
5. **Set `compatibility_date`**: Update quarterly to get new runtime features.
6. **Use `.dev.vars` for local secrets**: Never commit secrets to config.
7. **Test locally first**: `wrangler dev` with local bindings before deploying.
8. **Use `--dry-run` before major deploys**: Validate changes without deployment.
9. **Never embed secrets in commands**: Use interactive prompts (`wrangler secret put`), file-based input (`wrangler secret bulk`), or secure CI environment variables. Never echo, log, or pass secret values as CLI arguments.

## See Also

- [README.md](./README.md) - Overview
- [configuration.md](./configuration.md) - Config and bindings
- [api.md](./api.md) - Programmatic API
- [patterns.md](./patterns.md) - Workflows
- [gotchas.md](./gotchas.md) - Common issues
