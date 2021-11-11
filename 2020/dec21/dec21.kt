/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec21

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: lines of space-separated gibberish ingredients followed by "(contains …)" with a
comma-space separated list of English allergens. Each allergen comes from just one ingredient. */
val linePattern = Regex("""((?:\w+\s+)+)\(contains (\w+(?:,\s*\w+)*)\)""")

/* Count the number of ingredient occurrences that logically can't be any of the allergens. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val ingredientCounts = mutableMapOf<String, Int>()
    val allergenCandidates = mutableMapOf<String, Set<String>>()
    input.forEach { line ->
      linePattern.matchEntire(line)!!.let { match ->
        val ingredients = match.groupValues[1].trim().split(Regex("""\s+"""))
        val allergens = match.groupValues[2].trim().split(Regex(""",\s*"""))
        ingredients.forEach {
          ingredientCounts[it] = ingredientCounts.getOrDefault(it, 0) + 1
        }
        allergens.forEach {
          if (it in allergenCandidates) {
            allergenCandidates[it] = allergenCandidates.getValue(it).intersect(ingredients)
          } else {
            allergenCandidates[it] = ingredients.toSet()
          }
        }
      }
    }
    return (ingredientCounts.keys - allergenCandidates.values.flatten())
      .map(ingredientCounts::getValue).sum().toString()
  }
}

/* Output: comma-delimited list of unique gibberish ingredients sorted by English allergen. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    val knownIngredients = mutableSetOf<String>()
    val allergenCandidates = mutableMapOf<String, Set<String>>()
    input.forEach { line ->
      linePattern.matchEntire(line)!!.let { match ->
        val ingredients = match.groupValues[1].trim().split(Regex("""\s+"""))
        val allergens = match.groupValues[2].trim().split(Regex(""",\s*"""))
        knownIngredients.addAll(ingredients)
        allergens.forEach {
          if (it in allergenCandidates) {
            allergenCandidates[it] = allergenCandidates.getValue(it).intersect(ingredients)
          } else {
            allergenCandidates[it] = ingredients.toSet()
          }
        }
      }
    }
    val allergens = mutableMapOf<String, String>()
    val queue = allergenCandidates.mapValues { it.value.toMutableSet() }.toMutableMap()
    while (queue.isNotEmpty()) {
      // This makes things O(n^2) (and is kinda like a heap, but it changes several values on each
      // iteration), but the size of the structure is really small so whatever
      val (allergen, candidates) = checkNotNull(queue.entries.minByOrNull { it.value.size })
      check(candidates.size == 1) { "$allergen != 1 $candidates" }
      val ingredient = candidates.first()
      allergens[allergen] = ingredient
      queue.remove(allergen)
      queue.values.forEach { it.remove(ingredient) }
    }
    // println("${allergens.keys.sorted().joinToString(",")} translate to")
    return allergens.toSortedMap().values.joinToString(",")
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
