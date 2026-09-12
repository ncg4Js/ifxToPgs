# PostgreSQL — Functions, Procedures and Triggers

Source: PostgreSQL 18 documentation, §38 Server Programming / §39 PL/pgSQL / §37.4 Triggers
<https://www.postgresql.org/docs/current/plpgsql.html>
<https://www.postgresql.org/docs/current/plpgsql-trigger.html>

---

## Dollar quoting

The body of a routine is passed as a **string**. Use `$$` (or a tagged `$body$`) so
you do not have to escape internal quotes.

```sql
AS $$ ... $$;
```

Use a tag when nesting: `$outer$ ... $inner$ ... $inner$ ... $outer$`.

---

## Functions

```sql
CREATE OR REPLACE FUNCTION fn_name(p_id integer, p_name text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_count integer;
BEGIN
    SELECT count(*) INTO v_count FROM fruits WHERE entryid = p_id;
    RETURN v_count;
END;
$$;
```

Call with `SELECT fn_name(1, 'x');`

### Return types

| Declaration | Returns |
|---|---|
| `RETURNS integer` | one scalar |
| `RETURNS void` | nothing |
| `RETURNS fruits` | one row of that table's type |
| `RETURNS SETOF fruits` | many rows |
| `RETURNS TABLE(id int, n text)` | many rows, columns declared inline |
| `RETURNS trigger` | trigger use only — see below |

### Languages

- `LANGUAGE sql` — a single query, no variables or control flow. Faster, inlinable.
- `LANGUAGE plpgsql` — variables, `IF`, loops, exception handling. Use for anything procedural.

---

## Procedures

PostgreSQL 11+. A procedure returns **nothing** and is invoked with `CALL`.

```sql
CREATE OR REPLACE PROCEDURE pr_name(p_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fruits SET color = 'Red' WHERE entryid = p_id;
    COMMIT;
END;
$$;

CALL pr_name(1);
```

**The one real difference:** a procedure can `COMMIT` and `ROLLBACK` internally.
A function cannot — it always runs inside the caller's transaction.

Use a function unless you need that.

---

## Triggers

Two objects, always: a **trigger function** and a **trigger** that binds it to a table.

### 1. The function

```sql
CREATE OR REPLACE FUNCTION fn_bump_version() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.row_version := OLD.row_version + 1;
    RETURN NEW;
END;
$$;
```

- `RETURNS trigger` is a **pseudo-type**: the function can only be called by the
  trigger manager. `SELECT fn_bump_version();` is an error.
- The signature is **always empty**. Data arrives through implicit variables.
- It really returns a **row** of the triggering table (a composite value),
  never a scalar.

### 2. The trigger

```sql
CREATE TRIGGER trg_bump_version
    BEFORE UPDATE ON fruits
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)   -- optional
        EXECUTE FUNCTION fn_bump_version();
```

Clause order is fixed: timing/event → `FOR EACH ROW` → `WHEN` → `EXECUTE FUNCTION`.

`CREATE TRIGGER` is DDL. It has no `IF`, no variables, no procedural code —
conditions go in `WHEN (...)`, which takes a boolean expression.

### Implicit variables

| Variable | Contents |
|---|---|
| `NEW` | the new row — `INSERT`, `UPDATE`. Null otherwise. |
| `OLD` | the old row — `UPDATE`, `DELETE`. Null otherwise. |
| `TG_OP` | `'INSERT'` / `'UPDATE'` / `'DELETE'` / `'TRUNCATE'` |
| `TG_TABLE_NAME` | table the trigger fired on |
| `TG_WHEN`, `TG_LEVEL` | `'BEFORE'`/`'AFTER'`, `'ROW'`/`'STATEMENT'` |
| `TG_ARGV[]` | literal arguments from `CREATE TRIGGER`, always `text` |

Both `NEW` and `OLD` are null in statement-level triggers.

### What the return value means

| Trigger | Effect of returned value |
|---|---|
| `BEFORE ... FOR EACH ROW` | **The row you return is the row stored.** `NEW` = proceed, modified `NEW` = rewrite, `NULL` = skip this row. |
| `AFTER ... FOR EACH ROW` | Ignored. Use `RETURN NULL;` |
| `FOR EACH STATEMENT` | Ignored. Use `RETURN NULL;` |
| `INSTEAD OF` (views) | Non-null = "I handled it." |

Returning `OLD` from a `BEFORE UPDATE` trigger silently **discards the user's
changes** — it stores the old row. Almost never what you want.

---

## Rules of thumb

**Modifying the row being written → `BEFORE`.** Assign to `NEW`, return `NEW`.
Never issue an `UPDATE` against the trigger's own table.

**Acting on other tables after the fact → `AFTER`.** Issue the statement, `RETURN NULL;`

---

## Recursion

A trigger that runs `UPDATE` on its own table re-fires itself, without limit,
until `stack depth limit exceeded`. PostgreSQL does not detect the cycle.

The fix is `BEFORE` + assignment to `NEW`, which issues no second statement.

If you genuinely need `AFTER`, guard it:

```sql
IF pg_trigger_depth() > 1 THEN RETURN NULL; END IF;
```

Inside a trigger body the depth is **already 1**, so `> 1` means re-entered.
`= 0` is correct only in a `WHEN` clause, evaluated before the trigger is entered.

---

## Dropping

```sql
DROP TRIGGER  IF EXISTS trg_bump_version ON fruits;
DROP FUNCTION IF EXISTS fn_bump_version();
DROP PROCEDURE IF EXISTS pr_name(integer);
```

The **signature must match** or `IF EXISTS` silently drops nothing.
`DROP PROCEDURE` will not drop a function, and vice versa.
Dropping a table drops its triggers, but not the trigger functions.

---

## Common errors

| Message | Cause |
|---|---|
| `cannot return non-composite value from function returning composite type` | trigger function returned a scalar instead of `NEW`/`OLD`/`NULL` |
| `syntax error at or near "IF"` | procedural code placed inside `CREATE TRIGGER` — use `WHEN` |
| `stack depth limit exceeded` | trigger updates its own table |
| `function ... must return type trigger` | `CREATE TRIGGER` pointed at an ordinary function |
| `trigger functions can only be called as triggers` | called a trigger function with `SELECT` |

---

## Coming from Informix

| Informix | PostgreSQL |
|---|---|
| routine takes explicit arguments | signature is always empty; use `NEW`/`OLD`/`TG_*` |
| `REFERENCING OLD AS o NEW AS n` | not used; names are always `OLD` and `NEW` |
| action list inline in the trigger | only `EXECUTE FUNCTION fn();` |
| routine returns data | return value is a control signal, not data |

A mechanical port is wrong in all four ways at once.
