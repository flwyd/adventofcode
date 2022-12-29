/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day17

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: 2D grid of active (#) and inactive (.) cubes/hypercubes. Conway-style changes: each round,
active cubes become inactive unless they have 2 or 3 active neighbors; inactive cubes become active
if they have exactly 3 neighbors. Output: number of active cubes after 6 rounds. */

data class DimensionalCube(private val coordinates: List<Int>) {
  fun neighbors(): Sequence<DimensionalCube> {
    suspend fun SequenceScope<DimensionalCube>.recurse(prefix: List<Int>) {
      val position = prefix.size
      if (position == coordinates.size) {
        if (prefix != coordinates) { // cube isn't a neighbor to itself
          yield(DimensionalCube(prefix))
        }
      } else {
        for (i in coordinates[position] - 1..coordinates[position] + 1) {
          recurse(prefix + i)
        }
      }
    }
    return sequence { recurse(listOf()) }
  }
}

fun countActiveAfter(rounds: Int, dimensions: Int, initialState: Sequence<String>): Int {
  var prevActive = initialState.withIndex().flatMap { (x, line) ->
    line.toCharArray().withIndex().filter { it.value == '#' }.map { it.index }
      .map { y -> DimensionalCube(listOf(x, y, *Array(dimensions - 2) { 0 })) }
  }.toSet()
  repeat(rounds) {
    // Active cells remain active with 2 or 3 neighbors, inactive cells become active with 3
    prevActive =
      prevActive.flatMap(DimensionalCube::neighbors).groupingBy { it }.eachCount()
        .filter { (cube, count) -> count == 3 || (count == 2 && cube in prevActive) }.keys
  }
  return prevActive.size
}

object Part1 {
  fun solve(input: Sequence<String>): String {
    return countActiveAfter(6, 3, input).toString()
  }
}

object Part2 {
  fun solve(input: Sequence<String>): String {
    return countActiveAfter(6, 4, input).toString()
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
