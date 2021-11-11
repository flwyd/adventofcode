/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec13

import java.lang.Math.floorMod
import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: Two lines; the first is a timestamp of arrival, the second is a comma-separated list of
bus periods, with "x" values for buses that can be ignored. */

/* Output: time waiting for the first bust after timestamp, times bus period. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val lines = input.toList()
    val myTime = lines.first().toInt()
    return lines[1].split(",")
      .filter { it != "x" }
      .map(String::toInt)
      .associateWith { it - (myTime % it) }
      .minByOrNull { it.value }!!
      .let { (k, v) -> k * v }
      .toString()
  }
}

/* Ignore the first line. Output is the first time where each bus will be (it's position) time units
after that time. I.e. apply the Chinese Remainder Theorem to find a number x where x mod first = 0,
x mod fifth = 4, etc. */
object Part2 {
  fun solve(input: String): String {
    val pairs = input.split(",")
      .mapIndexed(::Pair)
      .filter { it.second != "x" }
      .map {
        it.second.toLong()
          .let { base -> (if (it.first == 0) 0L else base - (it.first % base)) to base }
      }
      .toList()
    val product = pairs.map { it.second }.reduce(Long::times)
    val sum = pairs.map {
      val coeff = bezoutCoefficients(it.second, product / it.second)
      it.first * coeff.second * (product / it.second)
    }.sum()
    return floorMod(sum, product).toString()
    // https://en.wikipedia.org/wiki/Chinese_remainder_theorem#Search_by_sieving
    // I implemented this quickly while trying to understand explanations of how Bézout's identity
    // can be used to compute the number which satisfies the Chinese Remainder Theorem constraints.
    // This sieve is exponential in the length of the result, and it didn't print the second line of
    // output in ~half an hour
//    println("Sieving for Chinese remainder of $pairs")
//    var sum = 0L
//    for (pair in pairs) {
//      while (sum % pair.second != pair.first) {
//        sum += pair.second
//      }
//      println("$sum % ${pair.second} = 0")
//    }
//    return sum.toString()
  }

  /* See https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm */
  private fun bezoutCoefficients(x: Long, y: Long): Pair<Long, Long> {
    var r0 = x
    var r1 = y
    var s0 = 1L
    var s1 = 0L
    var t0 = 0L
    var t1 = 1L
    while (true) {
      val q = r0 / r1
      val r = r0 % r1
      val s = s0 - q * s1
      val t = t0 - q * t1
      if (r == 0L) {
        return s1 to t1
      }
      r0 = r1
      r1 = r
      s0 = s1
      s1 = s
      t0 = t1
      t1 = t
    }
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
  // TimeSource.Monotonic.measureTimedValue { Part2.solve(lines.asSequence()) }.let {
  TimeSource.Monotonic.measureTimedValue { Part2.solve(lines[1]) }.let {
    println(it.value)
    println("Completed in ${it.duration}")
  }
//  println()
//  println("Extra examples:")
//  listOf("67,7,59,61", "67,x,7,59,61", "67,7,x,59,61", "1789,37,47,1889").forEach {
//    println(it)
//    println(Part2.solve(it))
//  }
}
