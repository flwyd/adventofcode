/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec16

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: three sections, the first is "field name: #-# or #-#", second starts with "your tickets:"
and is comma-delimited ints, third starts with "nearby tickets:" and is several lines of
comma-delimited ints. Fields are disjoint ranges of valid values. */

class DisjointIntRange(private val ranges: List<IntRange>) {
  companion object {
    fun parse(ranges: String): DisjointIntRange = DisjointIntRange(
      ranges.split(" or ")
        .map { it.split("-").let { (lo, hi) -> lo.toInt()..hi.toInt() } }
    )
  }

  operator fun contains(value: Int) = ranges.any { it.contains(value) }

  override fun toString(): String = ranges.joinToString(" or ")
}

/* Output: the product of all "nearby tickets" values that don't match any range. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val fields = mutableMapOf<String, DisjointIntRange>()
    val invalidValues = mutableListOf<Int>()
    var section = "fields"
    for (line in input.filterNot(String::isBlank)) {
      if (line.contains(':')) {
        val (prefix, value) = line.split(':')
        when (prefix) {
          "your ticket" -> section = "your"
          "nearby tickets" -> section = "nearby"
          else -> fields[prefix] = DisjointIntRange.parse(value.trim())
        }
      } else when (section) {
        "nearby" -> invalidValues.addAll(
          line.split(',').map(String::toInt).filter { value -> fields.values.none { value in it } }
        )
      }
    }
    return invalidValues.sum().toString()
  }
}

/* Throw out all rows with invalid values, then determine the field position for each field.
Output: product of the "your tickets" values for fields that start with "departure". */
object Part2 {
  fun solve(input: Sequence<String>): String {
    val fields = mutableMapOf<String, DisjointIntRange>()
    val possiblePositions = mutableMapOf<String, MutableSet<Int>>()
    var yourTicket = listOf<Int>()
    var section = "fields"
    for (line in input.filterNot(String::isBlank)) {
      if (line.contains(':')) {
        val (prefix, value) = line.split(':')
        when (prefix) {
          "your ticket" -> section = "your"
          "nearby tickets" -> {
            section = "nearby"
            fields.keys.forEach { possiblePositions[it] = (0 until fields.size).toHashSet() }
          }
          else -> fields[prefix] = DisjointIntRange.parse(value.trim())
        }
      } else when (section) {
        "your" -> yourTicket = line.split(',').map(String::toInt).toList()
        "nearby" -> {
          val values = line.split(',').map(String::toInt).toList()
          if (values.any { v -> fields.values.none { r -> v in r } }) {
            continue // invalid row
          }
          for ((i, value) in values.withIndex()) {
            for ((field, range) in fields) {
              if (value !in range) {
                possiblePositions.getValue(field).remove(i)
              }
            }
          }
        }
      }
    }
    fields.keys.sortedBy { possiblePositions.getValue(it).size }.forEach { field ->
      val possible = possiblePositions.getValue(field)
      if (possible.size == 1) {
        val theOne = possible.first()
        if (yourTicket[theOne] !in fields.getValue(field)) {
          error("Impossible value ${yourTicket[theOne]} for $field in $possible")
        }
        possiblePositions.filterKeys { it != field }.values.forEach { it.remove(theOne) }
      } else {
        error("Multiple possible values $possible for $field")
      }
    }
    // for actual input, only fields starting with "departure" matter, but example inputs
    // don't have any departure fields.
    val filtered =
        possiblePositions.filterKeys { it.startsWith("departure") }.ifEmpty { possiblePositions }
    return filtered
        .values.map(Set<Int>::first)
        .map(yourTicket::get)
        .map(Int::toLong)
        .reduce(Long::times).toString()
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
