/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 2
 * Read the puzzle at https://adventofcode.com/2020/day/2
 */

package day2

import runner.Day
import runner.runMain

data class PasswordLine(val min: Int, val max: Int, val letter: Char, val password: String) {
  val isValidPart1 get() = password.count { it == letter } in min..max

  val isValidPart2 get() = (password[min - 1] == letter) xor (password[max - 1] == letter)

  companion object {
    private val linePattern = Regex("""(\d+)-(\d+) (\w): (\w*)""")
    fun parse(line: String): PasswordLine {
      val match = linePattern.find(line) ?: throw IllegalArgumentException("Invalid line $line")
      val (min, max, letter, password) = match.destructured
      return PasswordLine(min.toInt(), max.toInt(), letter.single(), password)
    }
  }
}

object Day2 : Day {
  override fun part1(input: List<String>): String {
    return input
      .map(PasswordLine.Companion::parse)
      .filter(PasswordLine::isValidPart1)
      .count()
      .toString()
  }

  override fun part2(input: List<String>): String {
    return input
      .map(PasswordLine.Companion::parse)
      .filter(PasswordLine::isValidPart2)
      .count()
      .toString()
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day2, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
