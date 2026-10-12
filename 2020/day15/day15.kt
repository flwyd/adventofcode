/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 15
 * Read the puzzle at https://adventofcode.com/2020/day/15
 */

package day15

import runner.Day
import runner.runMain

/* Input is comma-delimited initial numbers. Say each initial number, then for each turn say how
many turns it had been since the previous number had been spoken. */

fun playToN(n: Int, initial: List<Int>): Int {
  val lastSeen = IntArray(n)
  var next = 0
  for (i in 1 until n) {
    if (i <= initial.size) {
      next = initial[i - 1]
    }
    val prev = i - lastSeen[next].let { if (it == 0) i else it }
    lastSeen[next] = i
    next = prev
  }
  // System.err.println("${lastSeen.size} uniques from $initial produced $next")
  return next
}

object Day15 : Day {
  /* Turn count is 2020. */
  override fun part1(input: List<String>): String {
    return input.map { it.split(",").map(String::toInt) }
      .map { playToN(2020, it) }
      .joinToString("\n")
  }

  /* Turn count is 30,000,000. */
  /* Maybe there's an analytic solution? The examples all involve 3,611,000 to 3,611,999 unique
  numbers, yet the final number ranges from 18 to over 6 million.
  Iterative solution takes a few seconds. */
  override fun part2(input: List<String>): String {
    return input.map { it.split(",").map(String::toInt) }
      .map { playToN(30_000_000, it) }
      .joinToString("\n")
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day15, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
