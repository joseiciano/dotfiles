# REST Patterns

## Resources

Plural nouns, with sub-resources for ownership. The HTTP method carries the verb, so URLs contain none:

```
GET    /api/tasks              → list (filters as query params)
POST   /api/tasks              → create
GET    /api/tasks/:id          → read one
PATCH  /api/tasks/:id          → partial update
DELETE /api/tasks/:id          → delete (idempotent)

GET    /api/tasks/:id/comments → list a sub-resource
POST   /api/tasks/:id/comments → create a sub-resource
```

## Status codes

Every error body uses the one error shape from `SKILL.md`.

| Code | Meaning |
|---|---|
| 400 | Request cannot be parsed: malformed JSON, missing required header |
| 401 | Not authenticated |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict: duplicate, version mismatch, in-flight idempotent request |
| 422 | Parsed, but fails schema or business validation |
| 500 | Server error; the body carries a code and a generic message only |

## Pagination

Every list endpoint paginates from its first release. Adding pagination later changes the response shape, which is a breaking change.

```typescript
// GET /api/tasks?page=1&pageSize=20&sortBy=createdAt&sortOrder=desc
{
  "data": [...],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 142, "totalPages": 8 }
}
```

## Partial updates

Use `PATCH` with a partial body: only the provided fields change, everything else is preserved. A `PUT` makes every client send the full object, and any field a client omits gets wiped.

```
PATCH /api/tasks/123
{ "title": "Updated title" }
```

## Checks

- [ ] Every URL names a resource; the HTTP method carries the verb
- [ ] Every error uses the status code from the table above
- [ ] Every list endpoint paginates
- [ ] Partial updates use `PATCH`
