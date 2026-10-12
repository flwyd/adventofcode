/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 10
 * Read the puzzle at https://adventofcode.com/2020/day/10
 */

package day10

import runner.Day
import runner.runMain

/* Input is a list of numbers which are 1, 2, or 3 larger than previous numbers. */

object Day10 : Day {
  /* Return the product of 1-gaps and 3-gaps. */
  override fun part1(input: List<String>): String {
    val list = input.map(String::toInt).toList().sorted()
    var ones = 0
    var threes = 0
    var prev = 0
    for (joltage in list) {
      when (joltage - prev) {
        1 -> ones++
        2 -> Unit // no-op
        3 -> threes++
        else -> throw IllegalStateException("Joltage delta not in 1-3")
      }
      prev = joltage
    }
    threes++ // final device is always highest+3
    return (ones * threes).toString()
  }

  /* Find the number of ways to chain from 0 to the final value with 1, 2, or 3 increments. */
  override fun part2(input: List<String>): String {
    val list = input.map(String::toInt).toList().sorted()
    val paths = mutableMapOf(0 to 1L)
    for (joltage in list) {
      var ways = 0L
      for (i in (joltage - 3)..(joltage - 1)) {
        if (i in paths) {
          ways += paths[i]!!
        }
      }
      paths[joltage] = ways
    }
    return paths[list.last()].toString()
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day10, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
