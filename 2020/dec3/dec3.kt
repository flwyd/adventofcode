/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec3

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is grid of . for open and # for blocked, conceptually extended infinitely to the right.
 * Moving right 3, down 1 each time, count the number of # blocks.
 */

object Part1 {
  fun solve(input: Sequence<String>): String {
    return input.withIndex()
      .filter { it.value[it.index * 3 % it.value.length] == '#' }
      .count()
      .toString()
  }
}

/* Now try with several slopes and multiply counts together. */
object Part2 {
  data class Slope(val right: Int, val down: Int, var obstacles: Long = 0)

  fun solve(input: Sequence<String>): String {
    val slopes = listOf(Slope(1, 1), Slope(3, 1), Slope(5, 1), Slope(7, 1), Slope(1, 2))
    input.withIndex().forEach { line ->
      slopes.forEach {
        if (line.index % it.down == 0 &&
          line.value[line.index / it.down * it.right % line.value.length] == '#'
        ) {
          it.obstacles++
        }
      }
    }
    // println(slopes)
    return slopes.map(Slope::obstacles).reduce(Long::times).toString()
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
