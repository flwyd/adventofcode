/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 6
 * Read the puzzle at https://adventofcode.com/2020/day/6
 */

package day6

import runner.Day
import runner.runMain

object Day6 : Day {
  /* Input: groups of lines with a-z, for each group find total letter counts, then sum them. */
  override fun part1(input: List<String>): String {
    return input.toParagraphs()
      .map { line -> line.associateWith { true }.filterKeys { it in 'a'..'z' }.size }
      .sum()
      .toString()
  }

  /* Now find just the counts of letters where all lines have a match. */
  override fun part2(input: List<String>): String {
    return input.toParagraphs()
      .map { para ->
        val matches = para.filter { it in 'a'..'z' }.toHashSet()
        para.split("\n").forEach { matches.retainAll(it.toSet()) }
        matches.size
      }
      .sum()
      .toString()
  }
}

fun List<String>.toParagraphs(): Sequence<String> {
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
fun main(args: Array<String>) {
  val result = runMain(Day6, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
