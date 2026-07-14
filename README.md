# Spotify + YouTube Track Analytics — Advanced SQL

End-to-end SQL analysis of ~20.6K music tracks across Spotify and YouTube: schema design, data-quality cleaning, 15 analytical queries progressing from basic aggregation to window functions and CTEs, and a query-optimization pass using `EXPLAIN ANALYZE` and B-tree indexing.

**Engine:** PostgreSQL 15 &nbsp;·&nbsp; **Dataset:** [Spotify and YouTube (Kaggle)](https://www.kaggle.com/datasets/salvatorerastelli/spotify-and-youtube) — 24 columns covering audio features, cross-platform engagement, and stream counts.

---

## Why this project

A single table with 24 columns is deceptively simple. The analytical questions are not: they need conditional aggregation to pivot platform rows into columns, window functions to build per-artist leaderboards, and CTEs to make multi-step logic readable. The last file goes further and asks the question most SQL projects skip — *is this query actually fast, and how do I prove it?*

---

## Repository structure

| File | What's in it |
|---|---|
| [`sql/01_schema.sql`](sql/01_schema.sql) | Table DDL + the data-quality checks run before any analysis (row counts, range checks, removal of corrupt zero-duration records) |
| [`sql/02_easy.sql`](sql/02_easy.sql) | Q1–Q5 — filtering, `DISTINCT`, `SUM` with NULL semantics, `GROUP BY` |
| [`sql/03_medium.sql`](sql/03_medium.sql) | Q6–Q10 — multi-column grouping, conditional aggregation (`CASE` inside `SUM`), derived tables |
| [`sql/04_advanced.sql`](sql/04_advanced.sql) | Q11–Q15 — `DENSE_RANK()` window functions, CTEs, scalar subqueries, running totals |
| [`sql/05_query_optimization.sql`](sql/05_query_optimization.sql) | `EXPLAIN ANALYZE` profiling, B-tree index creation, before/after plan comparison, and notes on when an index *doesn't* help |

---

## The analytical questions

**Tier 1 — Aggregation**
1. Tracks with more than 1 billion Spotify streams
2. All albums with their artists
3. Total comments on licensed tracks
4. Tracks belonging to album type `single`
5. Track count per artist

**Tier 2 — Conditional logic**
6. Average danceability per album
7. Top 5 tracks by energy
8. Views and likes for official-video tracks only
9. Total views per album–track pair
10. **Tracks streamed more on Spotify than on YouTube** — solved by pivoting platform rows into two columns with `CASE` inside `SUM`, guarding the NULL with `COALESCE`

**Tier 3 — Window functions & CTEs**
11. **Top 3 most-viewed tracks per artist** — `DENSE_RANK() OVER (PARTITION BY artist)`, ranked inside a CTE because window functions cannot be referenced in `WHERE`
12. Tracks with above-average liveness (scalar subquery)
13. Energy spread (max − min) per album, via `WITH`
14. Tracks with an energy-to-liveness ratio above 1.2
15. Cumulative likes ordered by views — running total using an implicit window frame

**Tier 4 — Optimization**
- Profile an artist-filtered query with `EXPLAIN ANALYZE` → planner reports a **sequential scan**
- Add a B-tree index on `artist`, run `ANALYZE` to refresh planner statistics
- Re-profile the identical query → planner switches to an **index scan**
- Verify actual index usage through `pg_stat_user_indexes`

---

## Decisions worth defending in an interview

- **`DISTINCT` in Q1 is not cosmetic.** A track can appear on both a studio album and a compilation, so the raw filter returns duplicates. Dropping `DISTINCT` inflates the result set.
- **Q10's `streamed_on_youtube <> 0` guard.** Without it, every Spotify-only track trivially satisfies "streamed more on Spotify than YouTube" (`n > 0`), and the result is meaningless.
- **`DENSE_RANK` over `ROW_NUMBER` in Q11.** With `ROW_NUMBER`, two tracks tied on views would arbitrarily land at ranks 3 and 4, and the `rank <= 3` filter would silently drop one of them.
- **The rank is computed in a CTE, not in `WHERE`.** `WHERE` is evaluated before window functions are materialised, so `WHERE DENSE_RANK() OVER (...) <= 3` is a syntax error, not a style preference.
- **An index on `most_played_on` would be useless.** Two distinct values means ~50% selectivity — Postgres will correctly ignore the index and seq-scan anyway.

---

## Running it

```bash
createdb spotify_analytics
psql -d spotify_analytics -f sql/01_schema.sql
# load the Kaggle CSV into the `spotify` table, then:
psql -d spotify_analytics -f sql/02_easy.sql
psql -d spotify_analytics -f sql/03_medium.sql
psql -d spotify_analytics -f sql/04_advanced.sql
psql -d spotify_analytics -f sql/05_query_optimization.sql
```

---

**Vivek Parashar** · B.Tech ECE, Delhi Technological University
[GitHub](https://github.com/vivekparashar999) · [LinkedIn](https://www.linkedin.com/in/vivek-parashar)
