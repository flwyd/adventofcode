/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec1

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is integers. Find the two which sum to 2020, print their product. */
object Part1 {
  fun solve(lines: Sequence<String>): String {
    val seen = mutableSetOf<Int>()
    return lines.map(String::toInt)
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
}

/* Input is integers. Find three which sum to 2020, print their product. */
object Part2 {
  fun solve(lines: Sequence<String>): String {
    val seen = mutableSetOf<Int>()
    val sums = mutableMapOf<Int, Pair<Int, Int>>()
    val results = mutableListOf<Int>()
    for (i in lines.map(String::toInt)) {
      if ((2020 - i) in sums) {
        results.add(sums.getValue(2020 - i).let { i * it.first * it.second })
      }
      seen.forEach { x: Int -> sums[x + i] = x to i }
      seen.add(i)
    }
    return results.joinToString("\n")
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
