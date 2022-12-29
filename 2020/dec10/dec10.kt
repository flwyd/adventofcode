/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec10

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is a list of numbers which are 1, 2, or 3 larger than previous numbers. */

/* Return the product of 1-gaps and 3-gaps. */
object Part1 {
  fun solve(input: Sequence<String>): String {
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
}

/* Find the number of ways to chain from 0 to the final value with 1, 2, or 3 increments. */
object Part2 {
  fun solve(input: Sequence<String>): String {
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
