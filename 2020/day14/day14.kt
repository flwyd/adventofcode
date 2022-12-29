/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day14

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is a sequence of instructions, either "mask = …" or "mem[x] = i". mask instructions set a
36-bit mask with X, 0, and 1 values. mem instructions set a memory value. Output is sum of all
values in memory at the end. */

/* Masks are applied to assigned values, with 0/1 overwriting bits and X leaving them untouched. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    var zeroMask = "1".repeat(36).toLong(2)
    var oneMask = 0L
    val mem = mutableMapOf<Int, Long>()
    val memPattern = Regex("""mem\[(\d+)\] = (\d+)""")
    for (line in input) {
      when {
        line.startsWith("mask") -> {
          val mask = line.replaceFirst("mask = ", "")
          zeroMask = mask.replace('X', '1').toLong(2)
          oneMask = mask.replace('X', '0').toLong(2)
        }
        line.startsWith("mem") -> {
          memPattern.find(line)!!.let {
            mem[it.groupValues[1].toInt()] = it.groupValues[2].toLong() and zeroMask or oneMask
          }
        }
        else -> {
          throw IllegalArgumentException("Unexpected $line")
        }
      }
    }
    return mem.values.sum().toString()
  }
}

/* Masks are applied to memory addresses, with 0 meaning "don't touch", 1 meaning "set to 1", and
X meaning "set to both 0 and 1." The number of memory sets per instruction is max(2^#x, 1). */
object Part2 {
  fun solve(input: Sequence<String>): String {
    var mask = "0".repeat(36)
    val memPattern = Regex("""mem\[(\d+)\] = (\d+)""")
    val mem = mutableMapOf<Long, Long>()
    for (line in input) {
      if (line.startsWith("mask")) {
        mask = line.replaceFirst("mask = ", "")
        if (mask.startsWith("XXXXXXXXX")) {
          // first example runs out of memory, example2 works for part2
          return "(skipped)"
        }
      } else if (line.startsWith("mem")) {
        memPattern.find(line)!!.destructured.let { (index, value) ->
          applyFloatingMask(mask, index.toLong()).forEach { mem[it] = value.toLong() }
        }
      }
    }
    // mem.entries.forEach { (k, v) -> println("$k = $v") }
    return mem.values.sum().toString()
  }

  private fun applyFloatingMask(mask: String, index: Long): Sequence<Long> {
    var base = 0L
    val floating = mutableListOf<Int>()
    mask.withIndex().forEach {
      val bitPosition = 35 - it.index
      when (it.value) {
        '0' -> base += index and (1L shl bitPosition)
        '1' -> base += 1L shl bitPosition
        'X' -> floating.add(bitPosition)
      }
    }
    if (floating.isEmpty()) {
      return sequenceOf(base)
    } else {
      // Inner function can't yield to an outer sequence, and Kotlin compiler gets confused when
      // a `fun x(…) = suspend {} function recurses, so set an extension on SequenceScope and
      // generate a sequence using that extension.
      // See https://github.com/Kotlin/kotlinx.coroutines/issues/7
      suspend fun SequenceScope<Long>.recurse(positions: List<Int>, value: Long) {
        if (positions.isEmpty()) {
          yield(value)
        } else {
          val next = positions.subList(1, positions.size)
          recurse(next, value)
          recurse(next, value or (1L shl positions.first()))
        }
      }
      return sequence { recurse(floating, base) }
    }
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
