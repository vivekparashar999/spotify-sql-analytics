-- =====================================================================
-- TIER 1 — Filtering, DISTINCT, aggregation, GROUP BY
-- =====================================================================

-- Q1. Retrieve the names of all tracks that have more than 1 billion streams.
-- DISTINCT is required: a track can appear on multiple albums/compilations.
SELECT DISTINCT track
FROM spotify
WHERE stream > 1000000000;


-- Q2. List all albums along with their respective artists.
SELECT DISTINCT album, artist
FROM spotify
ORDER BY 1;


-- Q3. Get the total number of comments for tracks where licensed = TRUE.
-- SUM() ignores NULLs, so unlicensed/missing rows do not corrupt the total.
SELECT SUM(comments) AS total_comments
FROM spotify
WHERE licensed = TRUE;


-- Q4. Find all tracks that belong to the album type 'single'.
-- String comparison is case-sensitive in PostgreSQL — 'Single' returns 0 rows.
SELECT track
FROM spotify
WHERE album_type = 'single';


-- Q5. Count the total number of tracks by each artist.
SELECT artist, COUNT(*) AS total_tracks
FROM spotify
GROUP BY artist
ORDER BY 2 DESC;
