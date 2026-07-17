# Spotify + YouTube SQL Analytics

SQL analysis of a Spotify/YouTube music dataset (~20.6K tracks, 24 columns) using PostgreSQL.

I wrote 15 queries going from basic aggregation up to window functions and CTEs, and then tried to optimize the slowest one using `EXPLAIN ANALYZE` and indexing.

**Dataset:** [Spotify and YouTube (Kaggle)](https://www.kaggle.com/datasets/salvatorerastelli/spotify-and-youtube)
**Tools:** PostgreSQL 15 — the analytical queries (window functions, CTEs, conditional aggregation) are standard SQL and portable to any modern engine

## Files

| File | Contents |
|---|---|
| `sql/01_schema.sql` | Table creation + data quality checks (row counts, range checks, removing bad rows) |
| `sql/02_easy.sql` | Q1–Q5: filtering, DISTINCT, SUM, GROUP BY |
| `sql/03_medium.sql` | Q6–Q10: grouping, CASE inside SUM, subqueries |
| `sql/04_advanced.sql` | Q11–Q15: window functions, CTEs, running totals |
| `sql/05_query_optimization.sql` | EXPLAIN ANALYZE, creating an index, before/after comparison |

## Questions solved

**Easy**
1. Tracks with more than 1 billion streams
2. All albums with their artists
3. Total comments on licensed tracks
4. Tracks with album type 'single'
5. Number of tracks per artist

**Medium**
6. Average danceability per album
7. Top 5 tracks by energy
8. Views and likes for official videos only
9. Total views per album
10. Tracks streamed more on Spotify than on YouTube

**Advanced**
11. Top 3 most viewed tracks for each artist (DENSE_RANK)
12. Tracks with above-average liveness
13. Energy difference (max − min) per album, using a CTE
14. Tracks with energy/liveness ratio above 1.2
15. Cumulative sum of likes ordered by views

## What I learned

- Window functions can't be used inside `WHERE`, so the ranking has to be done in a CTE first.
- `DENSE_RANK` works better than `ROW_NUMBER` here, otherwise tracks tied on views get dropped.
- Adding a B-tree index on `artist` changed the query plan from a sequential scan to an index scan.
- An index does not always help — on a column with only two values the planner ignores it anyway.

## How to run

```bash
createdb spotify_analytics
psql -d spotify_analytics -f sql/01_schema.sql
# load the CSV into the spotify table, then run the query files
psql -d spotify_analytics -f sql/02_easy.sql
psql -d spotify_analytics -f sql/03_medium.sql
psql -d spotify_analytics -f sql/04_advanced.sql
psql -d spotify_analytics -f sql/05_query_optimization.sql
```
