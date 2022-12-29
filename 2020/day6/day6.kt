/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day6

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: groups of lines with a-z, for each group find total letter counts, then sum them. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    return input
      .map { line -> line.associateWith { true }.filterKeys { it in 'a'..'z' }.size }
      .sum()
      .toString()
  }
}

/* Now find just the counts of letters where all lines have a match. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    return input
      .map { para ->
        val matches = para.filter { it in 'a'..'z' }.toHashSet()
        para.split("\n").forEach { matches.retainAll(it.toSet()) }
        matches.size
      }
      .sum()
      .toString()
  }
}

@ExperimentalTime
@Suppress("UNUSED_PARAMETER")
fun main(args: Array<String>) {
  val lines = generateSequence(::readLine).toParagraphs().toList()
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

fun Sequence<String>.toParagraphs(): Sequence<String> {
  var paragraph = mutableListOf<String>()
  return sequence {
    forEach { line ->
      if (line.isNotBlank()) {
        paragraph.add(line)
      } else {
        if (paragraph.isNotEmpty()) {
          yield(paragraph.joinToString("\n"))
        }
        paragraph = mutableListOf()
      }
    }
    if (paragraph.isNotEmpty()) {
      yield(paragraph.joinToString("\n"))
    }
  }
}
