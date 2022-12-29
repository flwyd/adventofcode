/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day2

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

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

object Part1 {
  fun solve(input: Sequence<String>): String {
    return input
      .map(PasswordLine.Companion::parse)
      .filter(PasswordLine::isValidPart1)
      .count()
      .toString()
  }
}

object Part2 {
  fun solve(input: Sequence<String>): String {
    return input
      .map(PasswordLine.Companion::parse)
      .filter(PasswordLine::isValidPart2)
      .count()
      .toString()
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
