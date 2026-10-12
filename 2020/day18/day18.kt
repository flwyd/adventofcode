/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 18
 * Read the puzzle at https://adventofcode.com/2020/day/18
 */

package day18

import runner.Day
import runner.runMain

/* Input: Lines of infix expressions with only +, *, parentheses, and integers.
Output: sum of expression value of each line. */

sealed class Token {
  interface Operator {
    fun op(a: Long, b: Long): Long
  }

  data class Number(val value: Long) : Token()
  object OpenParen : Token()
  object CloseParen : Token()
  object Plus : Token(), Operator {
    override fun op(a: Long, b: Long) = a + b
  }

  object Times : Token(), Operator {
    override fun op(a: Long, b: Long) = a * b
  }
}

val tokenPattern = Regex("""(\d+|[+*()])""")
fun parse(line: String): List<Token> = tokenPattern.findAll(line).map {
  when (val str = it.groupValues.first()) {
    "+" -> Token.Plus
    "*" -> Token.Times
    "(" -> Token.OpenParen
    ")" -> Token.CloseParen
    else -> Token.Number(str.toLong())
  }
}.toList()

object Day18 : Day {
  /* Parenthesized expressions first, but no precedence difference between + and *. */
  private fun evaluatePart1(tokens: Iterator<Token>): Long {
    var result = 0L
    var operator: Token.Operator = Token.Plus
    while (tokens.hasNext()) {
      when (val token = tokens.next()) {
        is Token.Number -> result = operator.op(result, token.value)
        is Token.Plus -> operator = token
        is Token.Times -> operator = token
        is Token.OpenParen -> result = operator.op(result, evaluatePart1(tokens))
        is Token.CloseParen -> return result
      }
    }
    return result
  }

  override fun part1(input: List<String>): String {
    return input.map(::parse).map { evaluatePart1(it.iterator()) }.sum().toString()
  }

  /* Parenthesized expressions first, + has higher precedence than *. */
  private fun evaluatePart2(tokens: Iterator<Token>): Long {
    val operators = ArrayDeque<Token.Operator>()
    val numbers = ArrayDeque<Long>()
    operators.addLast(Token.Plus)
    numbers.addLast(0L)
    fun accumulate(value: Long) {
      when (operators.lastOrNull()) {
        is Token.Plus -> numbers.addLast(operators.removeLast().op(numbers.removeLast(), value))
        is Token.Times -> numbers.addLast(value)
        else -> error("Accumulating $value on operator stack $operators")
      }
    }
    fun calculate(): Long {
      while (!operators.isEmpty()) {
        numbers.addLast(operators.removeLast().op(numbers.removeLast(), numbers.removeLast()))
      }
      check(numbers.size == 1) { "Expecting just one number, got $numbers" }
      return numbers.removeLast()
    }
    for (token in tokens) {
      when (token) {
        is Token.Number -> accumulate(token.value)
        is Token.Plus -> operators.addLast(token)
        is Token.Times -> operators.addLast(token)
        is Token.OpenParen -> accumulate(evaluatePart2(tokens))
        is Token.CloseParen -> return calculate()
      }
    }
    return calculate()
  }

  override fun part2(input: List<String>): String {
    return input.map(::parse).map { evaluatePart2(it.iterator()) }.sum().toString()
  }
}

fun main(args: Array<String>) {
  val result = runMain(Day18, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
