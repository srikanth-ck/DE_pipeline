# 06 — SQL Data Engineering Pipeline

This folder contains PostgreSQL-oriented examples for a dimension upsert (`MERGE`), range partitioning, bulk load using `COPY`, and composite/partial indexes.

**Requires PostgreSQL 15+** for `MERGE`. Execute sections individually in a disposable development database. `COPY ... FROM '/path'` reads a file accessible to the database server; `\copy` in `psql` reads from your client machine.

See `pipeline.sql` for the complete examples.
