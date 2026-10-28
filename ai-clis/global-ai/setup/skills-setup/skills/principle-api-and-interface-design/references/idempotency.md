# Honouring an Idempotency Key

Accepting an `Idempotency-Key` is the contract. Honouring it is the implementation, and it is where the money is lost. A key the server accepts but handles carelessly is worse than no key at all, because the client now believes retrying is safe.

Design for **at-least-once** delivery. No queue gives exactly-once across a consumer crash: the broker's ack and your side effect are not in one transaction. Duplicates are also *correlated*: retries spike exactly when a dependency is degraded, the moment duplicates are most likely and most expensive.

## Derive the key from the intent, not the attempt

The key is stable across retries of one intent and different across distinct intents:

```typescript
crypto.randomUUID()                    // ✗ new key per attempt: every retry is a new charge
`${userId}:${amount}`                  // ✗ two legitimate $50 charges collapse into one
`${orderId}:${Date.now()}`             // ✗ a timestamp is randomUUID() wearing a hat

req.headers['idempotency-key']         // ✓ client generates once, reuses on retry
`charge:v1:${orderId}`                 // ✓ derived from an immutable identifier
```

The key comes from the client or the initiating event, never from the layer doing the retrying.

## Claim atomically

A check followed by an act is a race. Let the unique constraint pick the winner:

```typescript
// ✗ TOCTOU: two concurrent retries both read "not seen", both charge
if (!(await db.exists(key))) {
  await chargeCard(amount);
  await db.insert(key);
}

// ✓
try {
  await db.insert({ key, state: 'in_progress', requestHash });
} catch (e) {
  if (isUniqueViolation(e)) return replayOrReject(key);
  throw e;
}
const result = await chargeCard(amount);
await db.update({ key, state: 'succeeded', response: result });
```

The unique constraint *is* the mechanism. A store that cannot enforce uniqueness in one operation cannot back this.

## Guard the payload

The same key with a different body is a client bug. Fail it loudly rather than serving the first response to the second request:

```typescript
if (existing.requestHash !== hash(req.body)) {
  return res.status(422).json({
    error: { code: 'IDEMPOTENCY_KEY_REUSED', message: 'Idempotency key reused with a different payload' },
  });
}
```

## Choose what an in-flight duplicate gets

The second request often arrives while the first is still running, the common case under retry storms. Pick one strategy deliberately:

| Strategy | Response | Use when |
|---|---|---|
| Reject | `409 Conflict` | Client can retry later; simplest and safest |
| Wait | Block for the result, bounded | Caller needs it synchronously |
| Return pending | `202` + status URL | Long-running effects |

A stalled first attempt still holds the key. Its fate is unknown, which is exactly when a duplicate costs most.

## Three outcomes: success, failure, unknown

A timeout says nothing about whether the effect applied. Record the intent *before* calling out, so a crash between the call and its response leaves evidence that something must resolve later.

## Retention

Set the key's retention from the longest path that can re-deliver the same intent, including a dead-letter queue replayed a week later and any provider dispute window. A 24-hour key TTL behind a 7-day DLQ is a duplicate waiting to happen.

## Checks

- [ ] The key is derived from the intent: client-supplied or built from an immutable identifier
- [ ] The key is claimed in one atomic operation, guarded by a unique constraint
- [ ] A reused key with a different payload returns `IDEMPOTENCY_KEY_REUSED`
- [ ] The in-flight-duplicate response is a deliberate choice: 409, bounded wait, or 202
- [ ] Intent is recorded before the external call, so an unknown outcome is recoverable
- [ ] Key retention outlives the longest retry path, including dead-letter replay
