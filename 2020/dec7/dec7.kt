/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec7

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is bag containment rules: "foo bar bags contain …" where containment is either
 * "no other bags" or a comma-space-delimited list of "# baz qux bag(s)".
 */

class Graph {
  private val contains = mutableMapOf<String, MutableMap<String, Int>>()
  private val contained = mutableMapOf<String, MutableMap<String, Int>>()

  fun addEdge(from: String, to: String, count: Int) {
    contains.computeIfAbsent(from) { mutableMapOf() }.putIfAbsent(to, count)
      ?.also {
        throw IllegalStateException("$contains already had $from + $to = $it not assigning $count")
      }
    contained.computeIfAbsent(to) { mutableMapOf() }.putIfAbsent(from, count)
      ?.also {
        throw IllegalStateException("$contained already had $to + $from = $it not assigning $count")
      }
  }

  fun getChildren(container: String): Map<String, Int> =
    contains.getOrDefault(container, mutableMapOf())

  fun getParents(containee: String): Map<String, Int> =
    contained.getOrDefault(containee, mutableMapOf())
}

val edgeLinePattern = Regex(
  """(\w+ \w+) bags contain (no other bags|(?:\d+ \w+ \w+ bags?(?:, \d+ \w+ \w+ bags?)*))\."""
)
val countBagPattern = Regex("""(\d+) (\w+ \w+) bags?""")
fun parseEdge(g: Graph, line: String) {
  val (container, rest) = edgeLinePattern.matchEntire(line)?.destructured
    ?: throw IllegalArgumentException("$line does not match $edgeLinePattern")
  if (rest != "no other bags") {
    for (match in countBagPattern.findAll(rest)) {
      val (count, containee) = match.destructured
      g.addEdge(container, containee, count.toInt())
    }
  }
}

/* Count the number of bag types that can transitively include a shiny gold bag. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val graph = Graph()
    input.forEach { parseEdge(graph, it) }
    val seen = mutableSetOf<String>()
    fun recurse(containee: String) {
      seen.add(containee)
      graph.getParents(containee).keys.filterNot(seen::contains).forEach(::recurse)
    }
    recurse("shiny gold")
    return seen.minus("shiny gold").size.toString()
  }
}

/* Count the transitive number of bags contained in a shiny gold bag. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    val graph = Graph()
    input.forEach { parseEdge(graph, it) }
    fun recursiveSum(parent: String): Int =
      graph.getChildren(parent).map { (child, count) -> count + count * recursiveSum(child) }.sum()
    return recursiveSum("shiny gold").toString()
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
