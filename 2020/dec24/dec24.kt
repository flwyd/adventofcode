/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec24

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: non-delimited lines consisting of e, w, se, sw, ne, nw instructions to move in those
six directions of a hexagonal grid, with each move list starting at the same tile. The final tile
is flipped over. */

/* Tiles are oriented with rows going east-west, northeast-southwest, southeast-northwest.
This can be represented by an x/y grid where each row is offset by ± half a tile. */
enum class Direction(val deltaWest: Float, val deltaNorth: Float) {
  EAST(-1.0f, 0.0f),
  WEST(1.0f, 0.0f),
  SOUTHEAST(-0.5f, -1.0f),
  SOUTHWEST(0.5f, -1.0f),
  NORTHEAST(-0.5f, 1.0f),
  NORTHWEST(0.5f, 1.0f)
}

data class HexTile(val west: Float, val north: Float) {
  fun neighbors() = Direction.values().map { HexTile(west + it.deltaWest, north + it.deltaNorth) }

  operator fun plus(dir: Direction) = HexTile(west + dir.deltaWest, north + dir.deltaNorth)
}

fun directionSequence(line: String) = sequence {
  var i = 0
  while (i < line.length) {
    when (line[i]) {
      'e' -> yield(Direction.EAST)
      'w' -> yield(Direction.WEST)
      's' -> when (line[++i]) {
        'e' -> yield(Direction.SOUTHEAST)
        'w' -> yield(Direction.SOUTHWEST)
        else -> error("Unexpected direction in $line")
      }
      'n' -> when (line[++i]) {
        'e' -> yield(Direction.NORTHEAST)
        'w' -> yield(Direction.NORTHWEST)
        else -> error("Unexpected direction in $line")
      }
      else -> error("Unexpected direction in $line")
    }
    i++
  }
}

/* Steps through each indicated direction and returns the identified tile. */
fun findTile(line: String) = directionSequence(line).fold(HexTile(0f, 0f), HexTile::plus)

/* Output: number of tiles which have been flipped an odd number of times after all input lines have
been followed. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    return input.map(::findTile).groupingBy { it }.eachCount().filterValues { it % 2 == 1 }.count()
      .toString()
  }
}

/* Output: Once the initial state from part 1 is established, run 100 rounds with the following
game-of-life type rules: flipped tiles remain flipped if they're adjacent to 1 or 2 other flipped
tiles; unflipped tiles are flipped if they're adjacent to 2 flipped tiles. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    var flipped =
      input.map(::findTile).groupingBy { it }.eachCount().filterValues { it % 2 == 1 }.keys.toSet()
    repeat(100) {
      val adjacent = flipped.flatMap { black -> black.neighbors().map { it to black } }
        .groupingBy { it.first }
        .eachCount()
      flipped = flipped.filter { adjacent[it] ?: 0 in 1..2 }.toSet() +
        adjacent.filterValues { it == 2 }.keys
    }
    return flipped.size.toString()
  }
}

@ExperimentalTime
@Suppress("UNUSED_PARAMETER")
fun main(args: Array<String>) {
  val lines = generateSequence(::readLine).toList()
  println("Part 1:")
  TimeSource.Monotonic.measureTimedValue { Part1.solve(lines.asSequence()) }.let {
    println(it.value)
    println("Completed in ${it.duration}")
  }
  println("Part 2:")
  TimeSource.Monotonic.measureTimedValue { Part2.solve(lines.asSequence()) }.let {
    println(it.value)
    println("Completed in ${it.duration}")
  }
}
