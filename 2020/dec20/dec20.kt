/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec20

import kotlin.math.sqrt
import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: paragraphs with Tile: 123 headings and square grids of . # points, with # meaning true.
Tiles can be joined side-by-side after arbitrary rotation and flip operations. */

// first value is Y axis (rows), second value is X axis (columns)
typealias Point = Pair<Int, Int>

operator fun Point.plus(other: Point) = Point(first + other.first, second + other.second)

infix fun Point.until(other: Point) =
  (first until other.first).flatMap { y -> (second until other.second).map { x -> y to x } }

fun toEdge(bools: Iterable<Boolean>) = bools.map { if (it) '#' else '.' }.joinToString("")

enum class Side(val index: Int) {
  NORTH(0) {
    override val opposite get() = SOUTH

    override fun fromPoint(start: Point): Point = start.first - 1 to start.second
  },
  EAST(1) {
    override val opposite get() = WEST

    override fun fromPoint(start: Point): Point = start.first to start.second + 1
  },
  SOUTH(2) {
    override val opposite get() = NORTH

    override fun fromPoint(start: Point) = start.first + 1 to start.second
  },
  WEST(3) {
    override val opposite get() = EAST

    override fun fromPoint(start: Point) = start.first to start.second - 1
  };

  abstract val opposite: Side
  abstract fun fromPoint(start: Point): Point
}

data class PixelPattern(val points: List<Point>) {
  val origin = checkNotNull(points.map(Point::first).minOrNull()) to checkNotNull(
    points.map(Point::second).minOrNull()
  )

  val maxCorner = checkNotNull(points.map(Point::first).maxOrNull()) to checkNotNull(
    points.map(Point::second).maxOrNull()
  )

  fun shifted(offset: Point) = PixelPattern(points.map { it + offset })

  companion object {
    fun parse(asciiArt: String): PixelPattern =
      PixelPattern(
        asciiArt.split("\n").withIndex().flatMap { (row, line) ->
          line.withIndex().filter { it.value == '#' }.map { row to it.index }
        }
      )
  }
}

data class Tile(val id: Int, val grid: List<List<Boolean>>) {
  init {
    check(grid.size == grid[0].size)
  }
  val size = grid.size
  val edges = listOf(
    toEdge(grid.first()),
    toEdge(grid.map { it.last() }),
    toEdge(grid.last()),
    toEdge(grid.map { it.first() }),
  )

  fun directionEdges() = Side.values().map { it to edges[it.index] }

  fun directionTo(other: Tile) = Side.values()
    .firstOrNull { side -> edges[side.index] == other.edges[side.opposite.index] }

  private fun flipVertical() = Tile(id, grid.reversed())

  private fun flipHorizontal() = Tile(id, grid.map(List<Boolean>::reversed))

  private fun rotateClockwise(): Tile {
    val lines = arrayOfNulls<BooleanArray>(grid[0].size)
    for (i in grid.indices) {
      lines[i] = BooleanArray(grid[0].size) { grid[it][i] }
    }
    return Tile(id, lines.map { it!!.toList() }.toList())
  }

  private fun rotations(): List<Tile> {
    val rotate1 = rotateClockwise()
    val rotate2 = rotate1.rotateClockwise()
    val rotate3 = rotate2.rotateClockwise()
    return listOf(rotate1, rotate2, rotate3)
  }

  fun variants(): Set<Tile> {
    val rotations = rotations()
    val vertical = flipVertical()
    val horizontal = flipHorizontal()
    val diagonal = vertical.flipHorizontal()
    return (
      rotations + vertical + vertical.rotations() +
        horizontal + horizontal.rotations() +
        diagonal + diagonal.rotations()
      ).toSet()
  }

  private fun matches(pattern: PixelPattern): Boolean {
    if (pattern.origin.first < 0 || pattern.origin.second < 0 ||
      pattern.maxCorner.first >= size || pattern.maxCorner.second >= size
    ) {
      return false
    }
    return pattern.points.all { grid[it.first][it.second] }
  }

  fun findMatches(pattern: PixelPattern) =
    grid.indices.flatMap { row ->
      grid.indices.map { col -> row to col }
        .filter { matches(pattern.shifted(it)) }
    }

  fun gridString() =
    grid.joinToString("\n") { line -> line.map { if (it) '#' else '.' }.joinToString("") }

  companion object {
    fun parse(paragraph: String): Tile {
      val lines = paragraph.split("\n")
      val id = lines[0].removePrefix("Tile ").removeSuffix(":").toInt()
      val grid = lines.drop(1).map { line ->
        line.toCharArray().map {
          when (it) {
            '.' -> false
            '#' -> true
            else -> error("Unexpected character $it")
          }
        }
      }
      return Tile(id, grid)
    }
  }
}

class TileGrid(val size: Int) {
  private val cells = (0 until size).map { arrayOfNulls<Tile>(size) }.toTypedArray()

  val allPoints = (0 to 0) until (size - 1 to size - 1)

  operator fun get(point: Point): Tile? = cells[point.first][point.second]

  operator fun set(point: Point, tile: Tile?) {
    cells[point.first][point.second] = tile
  }

  operator fun contains(point: Point) = point.first in 0 until size && point.second in 0 until size

  fun isSet(point: Point) = this[point] != null

  fun isUsed(tileId: Int) = allPoints.any { this[it]?.id == tileId }

  fun validPlacement(point: Point, tile: Tile, directions: Collection<Side>): Boolean {
    if (point !in this) {
      return false
    }
    for (dir in directions) {
      dir.fromPoint(point).let { neighborPoint ->
        if (neighborPoint !in this) {
          return false
        }
        this[neighborPoint]?.let { neighbor ->
          if (tile.directionTo(neighbor) != dir) {
            return false
          }
        }
      }
    }
    return true
  }

  fun copy(): TileGrid {
    val result = TileGrid(size)
    for (i in 0 until size) {
      for (j in 0 until size) {
        result[i to j] = this[i to j]
      }
    }
    return result
  }

  fun toStitchedTile(): Tile {
    check(allPoints.all { isSet(it) })
    val smallTileSize = cells[0][0]!!.size
    return Tile(
      0,
      (0 until size).flatMap { gridRow ->
        (1 until smallTileSize - 1).map { tileRow ->
          (0 until size).flatMap { gridCol ->
            cells[gridRow][gridCol]!!.grid[tileRow].subList(1, smallTileSize - 1)
          }
        }
      }
    )
  }

  override fun toString() =
    cells.joinToString("\n") { row -> row.map { it?.id }.joinToString("\t") }
}

/* Output: product of the ID of the four corners of the joined grid. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val originalTiles = input.toParagraphs().map { Tile.parse(it) }.toList()
    val originalById = originalTiles.map { it.id to it }.toMap()
    val withVariantsById = originalById.mapValues { it.value.variants() + it.value }
    val edgeIndex = mutableMapOf<String, MutableList<Tile>>()
    for (tile in withVariantsById.values.flatten()) {
      for (edge in tile.edges) {
        edgeIndex.getOrPut(edge, { mutableListOf() }).add(tile)
      }
    }
    var product = 1L
    for ((id, variants) in withVariantsById) {
      val matches =
        variants.flatMap(Tile::edges).toSet().flatMap { edgeIndex.getValue(it) }.map(Tile::id)
          .filter { it != id }.toSet()
      if (matches.size == 2) { // it's a corner
        product *= id
      }
    }
    return product.toString()
  }
}

/* Match a sea monster pattern to # positions. Output: number of # not covered by sea monster. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    val seaMonsterAsciiArt = """                  # 
#    ##    ##    ###
 #  #  #  #  #  #   """
    val seaMonster = PixelPattern.parse(seaMonsterAsciiArt)
    val originalTiles = input.toParagraphs().map { Tile.parse(it) }.toList()
    val originalById = originalTiles.map { it.id to it }.toMap()
    val withVariantsById = originalById.mapValues { it.value.variants() + it.value }
    val edgeIndex = mutableMapOf<String, MutableSet<Tile>>()
    for (tile in withVariantsById.values.flatten()) {
      for (edge in tile.edges) {
        edgeIndex.getOrPut(edge, { mutableSetOf() }).add(tile)
      }
    }
    val allMatches = mutableMapOf<Int, Set<Tile>>()
    val expectedDirections = mutableMapOf<Tile, Set<Side>>()
    val corners = mutableSetOf<Int>()
    for ((id, variants) in withVariantsById) {
      for (v in variants) {
        expectedDirections[v] = v.directionEdges()
          .filter { edgeIndex[it.second]!!.any { t -> t.id != v.id } }
          .map { it.first }.toSet()
      }
      allMatches[id] = variants.flatMap(Tile::edges).toSet().flatMap { edgeIndex.getValue(it) }
        .filter { it.id != id }.toSet()
      if (allMatches.getValue(id).map(Tile::id).toSet().size == 2) { // it's a corner
        corners.add(id)
      }
    }
    val gridSize = sqrt(originalTiles.size.toDouble()).toInt()

    fun recurse(
      grid: TileGrid,
      queue: Set<Point>,
      edgeExpected: Map<Point, Set<String>>
    ): TileGrid? {
      if (queue.isEmpty()) {
        for (point in grid.allPoints) {
          if (!grid.isSet(point)) {
            return null
          }
          return grid
        }
      }
      val myQueue = queue.mapTo(ArrayDeque()) { it }
      val point = myQueue.removeFirst()
      for (edge in edgeExpected.getValue(point)) {
        for (tile in edgeIndex.getValue(edge)) {
          if (grid.isUsed(tile.id)) {
            continue
          }
          if (grid.validPlacement(point, tile, expectedDirections.getValue(tile))) {
            // can add to the grid
            val myGrid = grid.copy()
            myGrid[point] = tile
            val q = myQueue.toMutableSet()
            val expected = edgeExpected.toMutableMap()
            for ((dir, e) in tile.directionEdges()) {
              val neighbor = dir.fromPoint(point)
              if (neighbor in myGrid) {
                expected[neighbor] = expected.getOrPut(neighbor, ::setOf) + e
                if (!myGrid.isSet(neighbor)) {
                  q.add(neighbor)
                }
              }
            }
            recurse(myGrid, q, expected)?.let { return it }
          }
        }
      }
      return null
    }

    val goodGrid = corners.asSequence().flatMap { cornerId ->
      withVariantsById.getValue(cornerId).asSequence()
        .filter { expectedDirections.getValue(it) == setOf(Side.EAST, Side.SOUTH) }.map { tile ->
          recurse(
            TileGrid(gridSize),
            setOf(0 to 0),
            mapOf(0 to 0 to setOf(tile.edges[Side.EAST.index], tile.edges[Side.SOUTH.index]))
          )
        }
    }.filterNotNull().first()
    // println("Found solution:")
    // println(goodGrid)
    val stitchedTile = goodGrid.toStitchedTile()
    // println(stitchedTile.gridString())
    // println("Sea monsters look like")
    // println(seaMonsterAsciiArt)
    for (orientation in listOf(stitchedTile) + stitchedTile.variants()) {
      val offsets = orientation.findMatches(seaMonster)
      if (offsets.isNotEmpty()) {
        val seaMonsterPoints =
          offsets.map { seaMonster.shifted(it) }.flatMap(PixelPattern::points).toSet()
        return ((0 to 0) until (stitchedTile.size to stitchedTile.size))
          .filterNot(seaMonsterPoints::contains)
          .filter { orientation.grid[it.first][it.second] }.count().toString()
      }
    }
    error("No sea monsters found in $goodGrid rotated")
  }
}

@ExperimentalTime
@Suppress("UNUSED_PARAMETER")
fun main(args: Array<String>) {
  val lines = generateSequence(::readLine).toList()
  print("part1: ")
  TimeSource.Monotonic.measureTimedValue { Part1.solve(lines.asSequence()) }.let {
    println(it.value)
    System.err.println("Completed in ${it.duration}")
  }
  print("part2: ")
  TimeSource.Monotonic.measureTimedValue { Part2.solve(lines.asSequence()) }.let {
    println(it.value)
    System.err.println("Completed in ${it.duration}")
  }
}

fun Sequence<String>.toParagraphs(): Sequence<String> {
  var paragraph = mutableListOf<String>()
  return sequence {
    forEach { line ->
      if (line.isNotBlank()) {
        paragraph.add(line)
      } else {
        if (paragraph.isNotEmpty()) {
          yield(paragraph.joinToString("\n"))
        }
        paragraph = mutableListOf()
      }
    }
    if (paragraph.isNotEmpty()) {
      yield(paragraph.joinToString("\n"))
    }
  }
}
