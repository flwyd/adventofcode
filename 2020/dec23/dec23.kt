/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec23

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: A string of digits, representing a cycle. Current cup is the first digit. Repeat N times:
1. Remove the three cups after the current cup from the cycle. 2: Destination value is current value
minus one, excluding the three cups just removed, and wrapping from min up to max. Insert the three
removed cups after the destination cup. Advance the current position by one. */

/* Model this as a linked list.  Standard library LinkedList class (and LinkedHashMap) doesn't make
splicing easy, so implement our own node class. */
class ListNode(val value: Int) {
  lateinit var next: ListNode

  fun take(n: Int): List<ListNode> {
    val result = mutableListOf<ListNode>()
    var node = this
    repeat(n) {
      result.add(node)
      node = node.next
    }
    return result
  }

  override fun toString(): String {
    val result = mutableListOf<Int>()
    var node = this
    do {
      result.add(node.value)
      node = node.next
    } while (node != this)
    return result.joinToString(",")
  }
}

/* CupCycle is a linked list that also provides a by-value node index and knows how to play a round
of the cup game. */
class CupCycle(initial: List<Int>, totalSize: Int) {
  // Reddit's /r/adventofcode commenters pointed out that a mapping from int to next int is
  // sufficient; we don't need both a map and a circular linked list.
  private val nodeIndex = mutableMapOf<Int, ListNode>()
  private val min = initial.minOrNull()!!
  private val max = totalSize + min - 1
  var cur = ListNode(initial.first())
  init {
    nodeIndex[cur.value] = cur
    var prev = cur
    for (i in initial.drop(1) + (initial.maxOrNull()!! + 1..max)) {
      val node = ListNode(i)
      prev.next = node
      nodeIndex[i] = node
      prev = node
    }
    prev.next = cur
  }

  fun playRound() {
    val slice = cur.next.take(3)
    val sliceVals = slice.map(ListNode::value)
    cur.next = slice.last().next
    var destVal = cur.value
    do {
      destVal = if (destVal <= min) max else destVal - 1
    } while (destVal in sliceVals)
    val dest = nodeIndex.getValue(destVal)
    slice.last().next = dest.next
    dest.next = slice.first()
    cur = cur.next
  }
}

/* Play 100 rounds, print the numbers in the cycle between "one after 1" and "one before 1". */
object Part1 {
  fun solve(input: Sequence<String>): String {
    return input.map { line ->
      val list = line.toCharArray().map(Char::toString).map(String::toInt)
      val cups = CupCycle(list, list.size)
      repeat(100) { cups.playRound() }
      var node = cups.cur
      while (node.value != 1) {
        node = node.next
      }
      node.next.take(list.size - 1).map(ListNode::value).joinToString("")
    }.joinToString("\n")
  }
}

/* Extend the list to contain one million cups and play ten million rounds. Output: product of the
two values following 1. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    return input.map { line ->
      val list = line.toCharArray().map(Char::toString).map(String::toInt)
      val cups = CupCycle(list, 1_000_000)
      repeat(10_000_000) { cups.playRound() }
      var node = cups.cur
      while (node.value != 1) {
        node = node.next
      }
      node.next.value.toLong() * node.next.next.value.toLong()
    }.joinToString("\n")
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
