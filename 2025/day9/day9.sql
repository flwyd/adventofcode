-- Advent of Code 2025 day 9
-- Read the puzzle at https://adventofcode.com/2025/day/9
-- Input is x,y points.
-- Part 1: area of the largest rectangle from a pair of points.
-- Part 2: area of the largest rectangle from a pair of points whose interior
-- is fully contained in the polygon formed by all points.

CREATE TEMPORARY TABLE points (x bigint, y bigint);
COPY points FROM STDIN (FORMAT CSV);

WITH boxes AS (
  SELECT ST_MakeEnvelope(a.x, a.y, b.x, b.y) AS box
  FROM
    (SELECT x, y, ROW_NUMBER() OVER (ORDER BY x, y) AS r FROM points) AS a
    CROSS JOIN
    (SELECT x, y, ROW_NUMBER() OVER (ORDER BY x, y) AS r FROM points) AS b
    WHERE b.r > a.r
), l AS (
  SELECT ST_MakeLine(ARRAY(SELECT ST_MakePoint(x, y) FROM points)) AS line
), p AS (
  SELECT ST_MakePolygon(ST_AddPoint(line, ST_StartPoint(line))) as poly FROM l
)
SELECT
  MAX(ST_Area(ST_Expand(box, 0.5, 0.5))) as part1,
  MAX(CASE WHEN ST_Contains(poly, box) THEN ST_Area(ST_Expand(box, 0.5, 0.5)) ELSE 0 END) AS part2
FROM boxes CROSS JOIN p;
