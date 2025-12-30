-- Advent of Code 2025 day 9
-- Read the puzzle at https://adventofcode.com/2025/day/9
-- Input is x,y points.
-- Part 1: area of the largest rectangle from a pair of points.
-- Part 2: area of the largest rectangle from a pair of points whose interior
-- is fully contained in the polygon formed by all points.

CREATE TEMPORARY TABLE points (x bigint, y bigint);
.mode csv
.import day9/input.example.txt points

WITH boxes AS (
  SELECT ST_Envelope(MakeLine(MakePoint(a.x, a.y), MakePoint(b.x, b.y))) AS box
  FROM
    (SELECT x, y, ROW_NUMBER() OVER (ORDER BY x, y) AS r FROM points) AS a
    CROSS JOIN
    (SELECT x, y, ROW_NUMBER() OVER (ORDER BY x, y) AS r FROM points) AS b
    WHERE b.r > a.r
), l AS (
  SELECT MakeLine(MakePoint(x, y)) AS line FROM points
), p AS (
  SELECT MakePolygon(AddPoint(line, StartPoint(line))) as poly FROM l
)
SELECT
  CAST(MAX(ST_Area(ST_Expand(box, 0.5))) AS integer) as part1,
  CAST(MAX(CASE WHEN ST_Contains(poly, box) THEN ST_Area(ST_Expand(box, 0.5)) ELSE 0 END) AS integer) AS part2
FROM boxes CROSS JOIN p;
.quit
