/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day9

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is a series of numbers. After the first w numbers, each number should be the sum of two
from the previous w numbers. Find the first violating number. */
object Part1 {
  fun solve(input: Sequence<String>, windowSize: Int = 25): String {
    return try {
      find(input, windowSize).toString()
    } catch (e: Exception) {
      e.toString()
    }
  }

  fun find(input: Sequence<String>, windowSize: Int = 25): Long {
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
}

/* A sequence of at least two numbers sums to the odd-number-out. Return the sum of the largest and
smallest numbers in that sequence. */
object Part2 {
  fun solve(input: Sequence<String>, windowSize: Int = 25): String {
    val match = Part1.find(input, windowSize)
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

@ExperimentalTime
@Suppress("UNUSED_PARAMETER")
fun main(args: Array<String>) {
  // input.example.txt uses windowSize=5, input.actual.txt uses windowSize=25
  val lines = generateSequence(::readLine).toList()
  val windowSize = if (lines.size < 30) { 5 } else { 25 }
  print("part1: ")
  TimeSource.Monotonic.measureTimedValue { Part1.solve(lines.asSequence(), windowSize) }.let {
    println(it.value)
    System.err.println("Completed in ${it.duration}")
  }
  print("part2: ")
  TimeSource.Monotonic.measureTimedValue { Part2.solve(lines.asSequence(), windowSize) }.let {
    println(it.value)
    System.err.println("Completed in ${it.duration}")
  }
}
