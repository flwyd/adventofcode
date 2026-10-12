/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

/**
 * Advent of Code 2020 day 25
 * Read the puzzle at https://adventofcode.com/2020/day/25
 */

package day25

import runner.Day
import runner.runMain

/* Input: Two lines with integer public keys in a Diffie–Hellman–Merkle style key exchange.
Transforming a value consists of repeating N (private key) times to set the current value to the
product of the current value (initially 1) by the subject value, modulo 20201227.  Public key is
the transformation of 7.  Encryption key is the transformation of the other side's public key.
Output is the encryption key. */

fun transformSubject(loopNumber: Int, subject: Int): Int {
  var value = 1L
  repeat(loopNumber) {
    value *= subject
    value %= 20201227
  }
  return value.toInt()
}

fun reverseTransform(pubKey: Int, subject: Int): Int {
  var count = 1
  var current = pubKey
  while (current != subject) {
    while (current % subject != 0) {
      current += 20201227
    }
    current /= subject
    count++
  }
  return count
}

object Day25 : Day {
  override fun part1(input: List<String>): String {
    val inputList = input.toList()
    check(inputList.size == 2)
    val pubKey1 = inputList.first().toInt()
    val pubKey2 = inputList.last().toInt()
    val loopNum1 = reverseTransform(pubKey1, 7)
    // println("loopNum1: $loopNum1 from $pubKey1")
    val loopNum2 = reverseTransform(pubKey2, 7)
    // println("loopNum2: $loopNum2 from $pubKey2")
    val encryptionKey1 = transformSubject(loopNum1, pubKey2)
    val encryptionKey2 = transformSubject(loopNum2, pubKey1)
    check(encryptionKey1 == encryptionKey2)
    return encryptionKey1.toString()
  }

  override fun part2(input: List<String>) = "Merry Christmas!"
}

fun main(args: Array<String>) {
  val result = runMain(Day25, args)
  kotlin.system.exitProcess(if (result) 0 else 1)
}
