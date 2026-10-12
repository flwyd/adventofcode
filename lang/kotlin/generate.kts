#!/usr/bin/env kotlin
/* Copyright 2026 Trevor Stone
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Generates a skeletal Advent of Code solution in Kotlin, along with a Makefile
 * and empty input files.
 * Usage: `generate.kts 2001/day1 ...`
 */

import java.nio.file.LinkOption.NOFOLLOW_LINKS
import java.nio.file.Path
import kotlin.io.path.Path
import kotlin.io.path.absolute
import kotlin.io.path.createDirectories
import kotlin.io.path.createFile
import kotlin.io.path.createSymbolicLinkPointingTo
import kotlin.io.path.div
import kotlin.io.path.exists
import kotlin.io.path.name
import kotlin.io.path.notExists
import kotlin.io.path.relativeTo
import kotlin.io.path.writeLines
import kotlin.io.path.writeText

if (args.isEmpty()) {
  System.err.println("Usage: generate.kts path/to/dayX ...")
  kotlin.system.exitProcess(1)
}
for (day in args) {
  createDay(day)
}

fun createDay(dayDir: String) {
  val dayPath = Path(dayDir)
  val day = dayPath.name
  val dayNum = day.replace(Regex("[^0-9]"), "")
  val parent = dayPath.absolute().parent
  val year = parent.name
  val copyDate = String.format("%tY", System.currentTimeMillis())
  val kotlin = dayPath / (day + ".kt")
  if (kotlin.exists()) {
    System.err.println("$kotlin already exists, not creating files")
    return
  }
  dayPath.createDirectories()
  println("Generating files in $dayPath")
  kotlin.writeText(generateKotlin(year, dayNum, copyDate))
  val makefile = dayPath / "Makefile"
  if (!makefile.exists()) {
    var root = parent
    while (root != null && (root / "lang" / "kotlin").notExists()) {
      root = root.parent
    }
    val rules = (root / "lang" / "kotlin" / "rules.mk").relativeTo(dayPath.absolute())
    makefile.writeText(generateMakefile(year, dayNum, copyDate, rules))
  }
  val exampleTxt = dayPath / "input.example.txt"
  val exampleExp = dayPath / "input.example.expected"
  if (!exampleTxt.exists()) {
    exampleTxt.createFile()
  }
  if (!exampleExp.exists()) {
    exampleExp.writeLines(listOf("part1: ", "part2: "))
  }
  val inputDir = parent / "input"
  if (inputDir.exists()) {
    val txt = inputDir / "input.actual.txt"
    val exp = inputDir / "input.actual.expected"
    if (txt.notExists()) {
      txt.createFile()
    }
    if (exp.notExists()) {
      exp.writeLines(listOf("part1: ", "part2: "))
    }
  } else {
    System.err.println("$inputDir does not exist")
  }
  for (f in listOf("input.actual.txt", "input.actual.expected")) {
    val inInput = inputDir / f
    val inDay = dayPath.absolute() / f
    if (inDay.notExists(NOFOLLOW_LINKS)) {
      inDay.createSymbolicLinkPointingTo(inInput.relativeTo(inDay.parent))
    }
  }
}

fun generateKotlin(year: String, dayNum: String, copyDate: String) =
"""/* Copyright $copyDate Trevor Stone
*
* Use of this source code is governed by an MIT-style
* license that can be found in the LICENSE file or at
* https://opensource.org/licenses/MIT.
*/

/**
 * Advent of Code $year day $dayNum
 * Read the puzzle at https://adventofcode.com/$year/day/$dayNum
 */
package day$dayNum

import runner.Day
import runner.runMain

object Day$dayNum : Day {
  override fun part1(input: List<String>): String {
    return "TODO"
  }

  override fun part2(input: List<String>): String {
    return "TODO"
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day$dayNum, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
"""

fun generateMakefile(year: String, dayNum: String, copyDate: String, rules: Path) =
"""# Copyright $copyDate Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# https://adventofcode.com/$year/day/$dayNum

DAY = day$dayNum

build: build-kotlin

clean: clean-kotlin

include $rules
"""
