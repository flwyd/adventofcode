/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec8

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input is "acc/jmp/nop +/-number" for accumulate, jump, or no-op. acc adds to an accumulator and
advances program counter by 1, jmp advances program counter, nop advances program counter by 1. */

sealed class Instruction {
  open val value = 0

  data class Acc(override val value: Int) : Instruction()
  data class Jmp(override val value: Int) : Instruction()
  data class Nop(override val value: Int) : Instruction()

  companion object {
    fun parse(inst: String): Instruction {
      val (ins, value) = inst.split(" ")
      return when (ins) {
        "acc" -> ::Acc
        "jmp" -> ::Jmp
        "nop" -> ::Nop
        else -> throw IllegalArgumentException("Unknown instruction $inst")
      }(value.toInt())
    }
  }
}

/* Outputs value of accumulator when program would loop. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val instructions = input.map(Instruction::parse).toList()
    var acc = 0
    var pc = 0
    val seen = mutableListOf<Int>()
    while (pc !in seen) {
      seen.add(pc)
      when (val inst = instructions[pc]) {
        is Instruction.Acc -> {
          acc += inst.value
          pc++
        }
        is Instruction.Jmp -> pc += inst.value
        is Instruction.Nop -> pc++
      }
    }
    return acc.toString()
  }
}

/* Replaces one jmp to a nop or vice versa to make the program terminate, then prints accumulated
value after running full program. */
object Part2 {
  sealed class InstructionList(val altUsed: Boolean) {
    abstract fun get(i: Int): Instruction
    open val size = 0

    class Base(private val list: List<Instruction>) : InstructionList(false) {
      override fun get(i: Int) = list[i]
      override val size = list.size
    }

    class Override(
      private val delegate: InstructionList,
      private val position: Int,
      private val replace: Instruction
    ) : InstructionList(true) {
      override fun get(i: Int) = if (i == position) replace else delegate.get(i)
      override val size = delegate.size
    }
  }

  private fun recurse(
    instructions: InstructionList,
    pc: Int,
    accumulator: Int,
    seen: MutableSet<Int>
  ): Int? {
    var acc = accumulator
    if (pc == instructions.size) {
      return acc
    }
    val inst = instructions.get(pc)
    if (pc in seen) {
      return null // loop detected
    }
    seen.add(pc) // push
    if (inst is Instruction.Acc) {
      acc += inst.value
    }
    val next = when (inst) {
      is Instruction.Acc -> pc + 1
      is Instruction.Nop -> pc + 1
      is Instruction.Jmp -> pc + inst.value
    }
    var result = recurse(instructions, next, acc, seen)
    seen.remove(pc) // pop
    if (result == null && !instructions.altUsed) {
      when (inst) {
        is Instruction.Nop -> Instruction.Jmp(inst.value)
        is Instruction.Jmp -> Instruction.Nop(inst.value)
        is Instruction.Acc -> null
      }?.let { result = recurse(InstructionList.Override(instructions, pc, it), pc, acc, seen) }
    }
    return result
  }

  fun solve(input: Sequence<String>): String {
    val base = InstructionList.Base(input.map(Instruction::parse).toList())
    return recurse(base, 0, 0, mutableSetOf())?.toString() ?: "no solution found"
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
