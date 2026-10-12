/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 9
 * Read the puzzle at https://adventofcode.com/2020/day/9
 */

package day9

import runner.Day
import runner.runMain

object Day9 : Day {
  /* Input is a series of numbers. After the first w numbers, each number should be the sum of two
  from the previous w numbers. Find the first violating number. */
  override fun part1(input: List<String>) =
    find(input, if (input.size < 30) 5 else 25).toString()

  fun find(input: List<String>, windowSize: Int = 25): Long {
    val window = ArrayDeque<Long>(windowSize)
    val available = mutableSetOf<Long>()
    input.map(String::toLong).forEach {
      if (window.size == windowSize) {
        if (window.firstOrNull { x -> available.contains(it - x) } == null) {
          return it // no match
        }
        available.remove(window.removeFirst())
      }
      if (it in available) {
        throw IllegalStateException("Duplicate value $it in $available")
      }
      window.add(it)
      available.add(it)
    }
    throw IllegalStateException("All values matched two previous, window is ${window.size}")
  }

  /* A sequence of at least two numbers sums to the odd-number-out. Return the sum of the largest
  and smallest numbers in that sequence. */
  override fun part2(input: List<String>): String {
    val windowSize = if (input.size < 30) 5 else 25
    val match = find(input, windowSize)
    val window = ArrayDeque<Long>(windowSize)
    var sum: Long = 0
    input.map(String::toLong).forEach {
      window.add(it)
      sum += it
      while (sum > match) {
        sum -= window.removeFirst()
      }
      if (sum == match && window.size > 1) {
        return (window.minOrNull()!! + window.maxOrNull()!!).toString()
      }
    }
    return "No sequence matched $match"
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day9, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
