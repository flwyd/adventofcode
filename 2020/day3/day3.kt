/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 3
 * Read the puzzle at https://adventofcode.com/2020/day/3
 */

package day3

import runner.Day
import runner.runMain

/* Input is grid of . for open and # for blocked, conceptually extended infinitely to the right.
 * Moving right 3, down 1 each time, count the number of # blocks.
 */

object Day3 : Day {
  override fun part1(input: List<String>): String {
    return input.withIndex()
      .filter { it.value[it.index * 3 % it.value.length] == '#' }
      .count()
      .toString()
  }

  /* Now try with several slopes and multiply counts together. */
  data class Slope(val right: Int, val down: Int, var obstacles: Long = 0)

  override fun part2(input: List<String>): String {
    val slopes = listOf(Slope(1, 1), Slope(3, 1), Slope(5, 1), Slope(7, 1), Slope(1, 2))
    input.withIndex().forEach { line ->
      slopes.forEach {
        if (line.index % it.down == 0 &&
          line.value[line.index / it.down * it.right % line.value.length] == '#'
        ) {
          it.obstacles++
        }
      }
    }
    // println(slopes)
    return slopes.map(Slope::obstacles).reduce(Long::times).toString()
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day3, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
