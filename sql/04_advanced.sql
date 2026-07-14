-- =====================================================================
-- TIER 3 — Window functions, CTEs, correlated subqueries, running totals
-- =====================================================================

-- Q11. Find the top 3 most-viewed tracks for each artist.
-- DENSE_RANK() over a PARTITION BY artist gives a per-artist leaderboard.
-- DENSE_RANK (not ROW_NUMBER) so genuine ties both survive the rank <= 3 filter.
-- The rank must be computed in a CTE: window functions cannot be used in WHERE,
-- because WHERE is evaluated before the window is materialised.
WITH ranking_artist AS (
    SELECT
        artist,
        track,
        SUM(views) AS total_view,
        DENSE_RANK() OVER (
            PARTITION BY artist
            ORDER BY SUM(views) DESC
        ) AS rank
    FROM spotify
    GROUP BY 1, 2
)
SELECT *
FROM ranking_artist
WHERE rank <= 3;


-- Q12. Find all tracks where the liveness score is above the dataset average.
-- Scalar subquery: the inner AVG is computed once, then compared row by row.
SELECT track, artist, liveness
FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify);


-- Q13. Use a WITH clause to find the difference between the highest and lowest
--      energy values for tracks in each album.
WITH cte AS (
    SELECT
        album,
        MAX(energy) AS highest_energy,
        MIN(energy) AS lowest_energy
    FROM spotify
    GROUP BY 1
)
SELECT
    album,
    highest_energy - lowest_energy AS energy_diff
FROM cte
ORDER BY 2 DESC;


-- Q14. Find tracks where the energy-to-liveness ratio is greater than 1.2.
-- liveness <> 0 guard prevents a division-by-zero error.
SELECT
    track,
    energy,
    liveness,
    (energy / liveness) AS ratio
FROM spotify
WHERE liveness <> 0
  AND (energy / liveness) > 1.2;


-- Q15. Calculate the cumulative sum of likes for tracks, ordered by number of views.
-- A window function with ORDER BY and no explicit frame defaults to
-- RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW — i.e. a running total.
SELECT
    track,
    views,
    likes,
    SUM(likes) OVER (ORDER BY views DESC) AS cumulative_likes
FROM spotify;
