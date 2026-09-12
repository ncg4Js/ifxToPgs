# PostgreSQL — Functions Available in Trigger Context

Companion to [postgres_procedures_functions.md](postgres_procedures_functions.md).

Source: PostgreSQL 18 documentation, §9.27 System Information Functions, §9.9 Date/Time Functions
<https://www.postgresql.org/docs/current/functions-info.html>
<https://www.postgresql.org/docs/current/functions-trigger.html>

---

## Trigger-specific

| Function | Returns |
|---|---|
| `pg_trigger_depth()` | trigger nesting level — `0` outside any trigger, `1` inside the outermost |

That is the only one. Everything about the *current* trigger comes from the
`TG_*` **variables** (`TG_OP`, `TG_NAME`, `TG_TABLE_NAME`, `TG_WHEN`, `TG_LEVEL`,
`TG_ARGV`), not from function calls. There is no `pg_trigger_name()`.

---

## Built-in trigger functions

Attach these directly — no function of your own needed.

```sql
CREATE TRIGGER trg_skip_noop
    BEFORE UPDATE ON fruits
    FOR EACH ROW
        EXECUTE FUNCTION suppress_redundant_updates_trigger();
```

`suppress_redundant_updates_trigger()` cancels an `UPDATE` whose new row is
identical to the old one — no write, no WAL, and **no `AFTER` triggers fire**.
Useful when an application rewrites whole rows blindly.

`tsvector_update_trigger()` — maintains a full-text search column.

---

## Timestamps

| Function | Frozen at |
|---|---|
| `now()` = `transaction_timestamp()` | start of the **transaction** |
| `statement_timestamp()` | start of the current **statement** |
| `clock_timestamp()` | the **actual clock** — advances within a statement |

For audit columns use `now()`: every row touched by one transaction then shares
a timestamp, which is what makes the trail groupable. Use `clock_timestamp()`
only when measuring elapsed time.

---

## Session and connection identity

```sql
current_user           -- effective user (changes under SECURITY DEFINER)
session_user           -- who actually logged in
current_database()
current_schema()
inet_client_addr()     -- NULL over a Unix socket
pg_backend_pid()
current_query()        -- full text of the statement being executed
pg_current_xact_id()   -- transaction id (older spelling: txid_current())
```

`current_user` vs `session_user` differ inside a `SECURITY DEFINER` function.
Audit triggers normally want `session_user`.

---

## Session variables

Triggers take no arguments, so this is how application context reaches them.

```sql
PERFORM set_config('myapp.user_id', '42', true);   -- true = transaction-local
SELECT current_setting('myapp.user_id', true);     -- true = return NULL if unset
```

The second argument to `current_setting` is `missing_ok`. **Omit it and an unset
variable raises an exception** instead of returning NULL.

---

## Row-level helpers

```sql
OLD.* IS DISTINCT FROM NEW.*     -- whole-row comparison, null-safe
to_jsonb(NEW)                    -- the entire row as JSON
to_jsonb(NEW) - 'row_version'    -- ... minus a column
```

`to_jsonb(NEW)` is what makes a **generic** audit trigger possible: one function
serving every table, storing the row as JSON and branching on `TG_TABLE_NAME`,
with no column list hardcoded anywhere.

---

## Debugging inside the body

```sql
RAISE NOTICE 'depth=% op=% row=%', pg_trigger_depth(), TG_OP, to_jsonb(NEW);
```

- `RAISE NOTICE` prints to the client (psql, and the Genero SQL trace).
- `RAISE EXCEPTION` aborts the statement.
- `FOUND` — boolean, set by the last statement.
- `GET DIAGNOSTICS v := ROW_COUNT;` — rows affected by the last DML statement.
