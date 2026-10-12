/*
 * Copyright 2026 Trevor Stone
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package runner

import kotlin.io.path.Path
import kotlin.io.path.div
import kotlin.io.path.exists
import kotlin.io.path.extension
import kotlin.io.path.name
import kotlin.io.path.nameWithoutExtension
import kotlin.io.path.pathString
import kotlin.io.path.readLines
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.DurationUnit
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/** Puzzle solutions implement this interface.  */
interface Day {
  fun part1(input: List<String>): String
  fun part2(input: List<String>): String
}

/** Runs a day implementation on files listed on the command line. */
fun runMain(day: Day, args: Array<String>): Boolean {
  val (verboseArg, filesArg) = args.partition { it == "-v" || it == "--verbose" }
  val files = if (filesArg.isEmpty()) listOf("-") else filesArg
  val verbose = !verboseArg.isEmpty()
  val dayName = day.javaClass.simpleName
  var result = true
  val expected = mutableMapOf<String, String>()
  for (filename in files) {
    val lines = if (filename == "-") {
      generateSequence(::readln).toList()
    } else {
      val path = Path(filename)
      if (path.extension == "txt") {
        val expPath = (path.parent ?: Path(".")) / (path.nameWithoutExtension + ".expected")
        if (expPath.exists()) {
          for (line in expPath.readLines()) {
            val (part, exp) = line.split(Regex(": *"))
            expected[part] = exp
          }
        }
      }
      path.readLines()
    }
    result = runPart("part1", dayName, filename, lines, expected, verbose, day::part1) || result
    result = runPart("part2", dayName, filename, lines, expected, verbose, day::part2) || result
  }
  return result
}

fun runPart(partName: String, dayName: String, filename: String, lines: List<String>,
expected: Map<String, String>, verbose: Boolean, part: (List<String>) -> String): Boolean {
  var result = true
  if (verbose) {
    System.err.println("Running $dayName $partName on $filename (${lines.size} lines)")
  }
  TimeSource.Monotonic.measureTimedValue { part(lines) }.let {
    println("$partName: ${it.value}")
    val exp = expected.getOrDefault(partName, "")
    val outcome = when {
      it.value == exp -> Success(it.value)
      it.value == "TODO" -> Todo(exp)
      exp.isEmpty() -> Unknown(it.value)
      else -> Failure(it.value, exp)
    }
    if (outcome is Failure) {
      result = false
    }
    if (verbose) {
      System.err.println(outcome.toString())
      val dur = it.duration
      val time = when {
        dur > 1.minutes -> dur.toComponents { min, sec, _ -> String.format("%d:%02d", min, sec) }
        dur > 1.seconds -> dur.toString(DurationUnit.SECONDS, 3)
        dur > 1.milliseconds -> dur.toString(DurationUnit.MILLISECONDS, 0)
        else -> dur.toString(DurationUnit.MICROSECONDS, 0)
      }
      System.err.println("$partName took $time on $filename")
    }
  }
  if (verbose) {
    System.err.println("=".repeat(40))
  }
  return true
}

sealed class Outcome(val name: String, val emoji: String, val color: String,
val description: String) {
  override fun toString() = String.format("$emoji \u001B[${color}m$name\u001B[0m $description")
}

// Part got correct result, bright green background.
class Success(val result: String) : Outcome("SUCCESS", "✅", "30;102", "got $result")

// Part not implemented yet, bright cyan background.
class Todo(val expected: String) :
Outcome("TODO", "❗", "30;106",
String.format("implement it%s", if (expected.isEmpty()) "" else ", want $expected"))

// Unknown expected value, bright yellow background.
class Unknown(val result: String) : Outcome("UNKNOWN", "❓", "30;103", "got $result")

// Part got wrong result, bright red background.
class Failure(val result: String, val expected: String) :
Outcome("FAILURE", "❌", "30;101", "got $result, want $expected")
