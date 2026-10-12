/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 5
 * Read the puzzle at https://adventofcode.com/2020/day/5
 */

package day5

import runner.Day
import runner.runMain

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

object Day5 : Day {
  /* Return the largest seat ID. */
  override fun part1(input: List<String>): String {
    return seatIds(input.asSequence()).maxOrNull()?.toString() ?: "Empty input"
  }

  /* Return the missing seat ID, with some at the beginning and end not in the available set. */
  override fun part2(input: List<String>): String {
    val sorted = seatIds(input.asSequence()).toList().sorted()
    for ((index, id) in sorted.withIndex()) {
      if (id - index != sorted.first()) {
        return (id - 1).toString()
      }
    }
    return "Open seat ID not found"
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day5, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
