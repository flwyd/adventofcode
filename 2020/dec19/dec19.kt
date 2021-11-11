/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec19

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: Two sections, blank line delimited. First section is rules with an int rule ID followed
by colon and then rule definition. Rules can be a string ("x"), a space-separated sequence of rule
IDs, or a pipe-delimited disjunction of sequences. The second section are strings; check if the
whole string matches rule 0. */

/* This would probably by parsing the rules as a BNF-style lexer. */
sealed class Rule {
  abstract fun matches(text: CharSequence, rules: Map<Int, Rule>): List<Int>

  companion object {
    private val orPattern = Regex("""\s*\|\s*""")
    private val seqPattern = Regex("""\s+""")

    fun parse(text: String): Rule {
      return when {
        text.startsWith("\"") -> Str(text.removeSurrounding("\""))
        text.contains("|") -> Or(text.split(orPattern).map { parse(it) }.toList())
        else -> Seq(text.split(seqPattern).map(String::toInt).toList())
      }
    }
  }

  data class Str(val str: String) : Rule() {
    override fun matches(text: CharSequence, rules: Map<Int, Rule>): List<Int> {
      return if (str == text.take(str.length)) listOf(str.length) else listOf()
    }
  }

  data class Seq(val ruleIndices: List<Int>) : Rule() {
    override fun matches(text: CharSequence, rules: Map<Int, Rule>): List<Int> {
      if (text.isEmpty() || ruleIndices.isEmpty()) {
        return listOf()
      }
      val rule = rules.getValue(ruleIndices[0])
      if (ruleIndices.size == 1) {
        return rule.matches(text, rules)
      }
      return rules.getValue(ruleIndices[0])
        .matches(text, rules)
        .flatMap { len -> Seq(ruleIndices.drop(1)).matches(text.drop(len), rules).map { len + it } }
    }
  }

  data class Or(val choices: List<Rule>) : Rule() {
    override fun matches(text: CharSequence, rules: Map<Int, Rule>): List<Int> {
      return choices.asSequence().flatMap { it.matches(text, rules) }.toList()
    }
  }
}

val linePattern = Regex("""(\d+):\s*(.*)""")

/* Rules can't create cycles. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val rules = mutableMapOf<Int, Rule>()
    val iter = input.iterator()
    while (iter.hasNext()) {
      val line = iter.next()
      if (line.isBlank()) {
        break
      }
      linePattern.matchEntire(line)!!.let { match ->
        val id = match.groupValues[1].toInt()
        val rule = Rule.parse(match.groupValues[2])
        rules[id] = rule
      }
    }
    return Iterable { iter }.filter(String::isNotBlank)
      .flatMap { line -> rules.getValue(0).matches(line, rules).filter { it == line.length } }
      .count().toString()
  }
}

/* Rules can create cycles in some circumstances; problem statement has two rule replacements. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    val replacements = mapOf(8 to "42 | 42 8", 11 to "42 31 | 42 11 31")
    val rules = mutableMapOf<Int, Rule>()
    val iter = input.iterator()
    while (iter.hasNext()) {
      val line = iter.next()
      if (line.isBlank()) {
        break
      }
      linePattern.matchEntire(line)!!.let { match ->
        val id = match.groupValues[1].toInt()
        val rule = Rule.parse(
          if (id in replacements) replacements.getValue(id) else match.groupValues[2]
        )
        rules[id] = rule
      }
    }
    return Iterable { iter }.filter(String::isNotBlank)
      .flatMap { line -> rules.getValue(0).matches(line, rules).filter { it == line.length } }
      .count().toString()
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
