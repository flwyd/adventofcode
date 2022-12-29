/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec5

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: 7 F or B then 3 L or R representing 7-digit binary row # and 3-digit binary column #.
 * Output seat ID is 8 * row + col.
 * This implementation doesn't use binary operators because the problem description got me in the
 * mental space of splitting ranges in two, which is more awkward than I expected.
 */
fun seatIds(input: Sequence<String>): Sequence<Int> {
  return input
    .map { line ->
      var rows = 0..127
      line.asSequence().take(7).forEach {
        val size = rows.last - rows.first + 1
        rows = when (it) {
          'F' -> rows.first..rows.last - size / 2
          'B' -> rows.first + size / 2..rows.last
          else -> throw IllegalArgumentException("Unexpected $it in $line")
        }
      }
      var cols = 0..7
      line.asSequence().drop(7).forEach {
        val size = cols.last - cols.first + 1
        cols = when (it) {
          'L' -> cols.first..cols.last - size / 2
          'R' -> cols.first + size / 2..cols.last
          else -> throw IllegalArgumentException("Unexpected $it in $line")
        }
      }
      if (rows.first != rows.last || cols.first != cols.last) {
        throw IllegalArgumentException("Left over $rows, $cols from $line")
      }
      rows.first to cols.first
    }
    .map { it.first * 8 + it.second }
}

/* Return the largest seat ID. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    return seatIds(input).maxOrNull()?.toString() ?: "Empty input"
  }
}

/* Return the missing seat ID, with some at the beginning and end not in the available set. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    val sorted = seatIds(input).toList().sorted()
    for ((index, id) in sorted.withIndex()) {
      if (id - index != sorted.first()) {
        return (id - 1).toString()
      }
    }
    return "Open seat ID not found"
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
