/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 1
 * Read the puzzle at https://adventofcode.com/2020/day/1
 */

package day1

import runner.Day
import runner.runMain

object Day1 : Day {
  /* Input is integers. Find the two which sum to 2020, print their product. */
  override fun part1(input: List<String>): String {
    val seen = mutableSetOf<Int>()
    return input.map(String::toInt)
      .filter {
        try {
          (2020 - it) in seen
        } finally {
          seen.add(it)
        }
      }
      // .map { it.also(seen::add) } // would incorrectly match 1010 with itself
      // .filter { (2020 - it) in seen }
      .map { it * (2020 - it) }
      .joinToString("\n")
  }

  /* Input is integers. Find three which sum to 2020, print their product. */
  override fun part2(input: List<String>): String {
    val seen = mutableSetOf<Int>()
    val sums = mutableMapOf<Int, Pair<Int, Int>>()
    val results = mutableListOf<Int>()
    for (i in input.map(String::toInt)) {
      if ((2020 - i) in sums) {
        results.add(sums.getValue(2020 - i).let { i * it.first * it.second })
      }
      seen.forEach { x: Int -> sums[x + i] = x to i }
      seen.add(i)
    }
    return results.joinToString("\n")
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day1, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
