/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day4

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is whitespace-separated key:value pairs. Count number with required keys are present. */
object Part1 {
  private val required = setOf("byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid") // cid is optional
  private val whitespace = Regex("""\s+""")

  fun solve(input: Sequence<String>): String {
    return input
      .map { line -> whitespace.split(line).map { it.substringBefore(':') } }
      .filter { it.containsAll(required) }
      .count()
      .toString()
  }
}

/* Now validate value rules. */
object Part2 {
  enum class Field(val pattern: Regex) {
    BYR(Regex("""\d{4}""")) {
      override fun validate(value: String) = pattern.matches(value) && value.toInt() in 1920..2002
    },
    IYR(Regex("""\d{4}""")) {
      override fun validate(value: String) = pattern.matches(value) && value.toInt() in 2010..2020
    },
    EYR(Regex("""\d{4}""")) {
      override fun validate(value: String) = pattern.matches(value) && value.toInt() in 2020..2030
    },
    HGT(Regex("""(\d+)(cm|in)""")) {
      override fun validate(value: String) = pattern.matchEntire(value)?.let {
        val (_, height, units) = it.groupValues
        when (units) {
          "cm" -> height.toInt() in 150..193
          "in" -> height.toInt() in 59..76
          else -> throw IllegalArgumentException("$value has unknown units")
        }
      } ?: false
    },
    HCL(Regex("""#[0-9a-f]{6}""")),
    ECL(Regex("""amb|blu|brn|gry|grn|hzl|oth""")),
    PID(Regex("""\d{9}"""));

    open fun validate(value: String) = pattern.matches(value)
  }
  private val whitespace = Regex("""\s+""")

  fun solve(input: Sequence<String>): String {
    return input
      .map { whitespace.split(it) }
      .filter { fields ->
        fields.map { it.split(':') }
          .filter { it[0] != "cid" }
          .filter { Field.valueOf(it[0].uppercase()).validate(it[1]) }
          .count() == Field.values().size
      }
      .count()
      .toString()
  }
}

@ExperimentalTime
@Suppress("UNUSED_PARAMETER")
fun main(args: Array<String>) {
  val lines = generateSequence(::readLine).toParagraphs().toList()
  // println("Lines has ${lines.size} paragraphs")
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
