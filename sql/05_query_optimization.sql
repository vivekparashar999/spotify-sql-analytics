-- =====================================================================
-- TIER 4 — Query optimization: profiling with EXPLAIN ANALYZE, indexing
-- =====================================================================
-- The `artist` column is the hottest filter in this workload (per-artist
-- leaderboards, top-N by artist, artist track counts). On a heap table with
-- no index, every one of those queries forces a full sequential scan.
--
-- Run each block below in order and record the planner output.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1 — Baseline: profile the query BEFORE any index exists
-- ---------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT artist, track, views
FROM spotify
WHERE artist = 'Gorillaz'
  AND most_played_on = 'Youtube'
ORDER BY stream DESC
LIMIT 25;

-- Expected plan: "Seq Scan on spotify"  — Postgres reads every row in the
-- table and discards the non-matching ones. Note the reported
-- `Execution Time` and `Planning Time`.


-- ---------------------------------------------------------------------
-- STEP 2 — Create a B-tree index on the filter column
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_spotify_artist ON spotify (artist);

-- Refresh planner statistics so the optimizer knows the index exists
-- and knows the column's selectivity.
ANALYZE spotify;


-- ---------------------------------------------------------------------
-- STEP 3 — Re-profile the identical query AFTER indexing
-- ---------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT artist, track, views
FROM spotify
WHERE artist = 'Gorillaz'
  AND most_played_on = 'Youtube'
ORDER BY stream DESC
LIMIT 25;

-- Expected plan: "Bitmap Index Scan on idx_spotify_artist" (or Index Scan).
-- Postgres now jumps straight to the matching rows instead of scanning the
-- whole table. Compare `Execution Time` against the STEP 1 baseline.


-- ---------------------------------------------------------------------
-- STEP 4 — Verify the index is actually being used
-- ---------------------------------------------------------------------
SELECT
    indexrelname AS index_name,
    idx_scan     AS times_used,
    idx_tup_read AS tuples_read
FROM pg_stat_user_indexes
WHERE relname = 'spotify';

-- idx_scan = 0 means the planner is ignoring the index (usually because the
-- filter is not selective enough, or ANALYZE was never run).


-- ---------------------------------------------------------------------
-- NOTES — when an index does NOT help
-- ---------------------------------------------------------------------
-- 1. Low-selectivity columns: an index on `most_played_on` (only two distinct
--    values) is useless — a seq scan is cheaper than a random-access index
--    lookup for ~50% of the table.
-- 2. Every index slows down INSERT/UPDATE/DELETE, because the B-tree must be
--    maintained on write. Index read-heavy analytical columns only.
-- 3. Queries with no WHERE clause (e.g. the Q15 running total over the whole
--    table) will always seq-scan. No index will change that.
