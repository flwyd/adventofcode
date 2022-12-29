/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package day22

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: "Player 1:" and "Player 2:" followed by a list of integers, one per line, representing
cards in two halves of a deck.  Output: winning player's score. */

fun parseDecks(input: Sequence<String>): List<Deck> {
  val result = mutableListOf<Deck>()
  var name = ""
  var cards = ArrayDeque<Int>()
  input.forEach { line ->
    if (line.startsWith("Player")) {
      if (name.isNotEmpty()) {
        result.add(Deck(name, cards))
      }
      name = line.removeSuffix(":")
      cards = ArrayDeque()
    } else if (line.isNotBlank()) {
      cards.addLast(line.toInt())
    }
  }
  result.add(Deck(name, cards))
  return result.toList().also { check(it.size == 2) { "Unexpected player count: $result" } }
}

data class Deck(val name: String, private val cards: ArrayDeque<Int>) {
  fun score(): Long {
    return cards.reversed().withIndex().map { (it.index + 1) * it.value.toLong() }.sum()
  }

  fun size() = cards.size

  fun isNotEmpty() = cards.isNotEmpty()

  fun draw() = cards.removeFirst()

  fun addWinnings(card1: Int, card2: Int) {
    cards.addLast(card1)
    cards.addLast(card2)
  }

  fun take(count: Int) = copy(cards = ArrayDeque(cards.take(count)))
}

/* Game: Flip top two; winner has higher value card and gets both cards at the bottom of their deck,
with their flipped card first. Game ends when one player has no cards left; winner's score is the
product of the bottom-up index times card value. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val (player1, player2) = parseDecks(input)
    while (player1.isNotEmpty() && player2.isNotEmpty()) {
      val card1 = player1.draw()
      val card2 = player2.draw()
      check(card1 != card2) { "$card1 = $card2" }
      if (card1 > card2) {
        player1.addWinnings(card1, card2)
      } else {
        player2.addWinnings(card2, card1)
      }
    }
    return listOf(player1, player2).first(Deck::isNotEmpty).score().toString()
  }
}

/* Game: similar to part 1, but if the number both players draw is less than or equal to the number
of cards left in their deck, play a recursive game where both players start with a copy of the first
N cards in their deck, where N is the number they just drew; the winner of that game gets the two
cards drawn in this round, even if their card was lower. If the two decks before a draw are in
an identical state to those in previous round, player 1 wins to prevent infinite loops.
 */
object Part2 {
  private fun recursiveCombat(player1: Deck, player2: Deck): Deck {
    val nextPrevious = mutableSetOf<Pair<Deck, Deck>>()
    while (player1.isNotEmpty() && player2.isNotEmpty()) {
      if (player1 to player2 in nextPrevious) {
        return player1 // rule: if the exact same deck state has been seen before, player 1 wins
      }
      nextPrevious.add(player1 to player2)
      val card1 = player1.draw()
      val card2 = player2.draw()
      val winner = if (card1 <= player1.size() && card2 <= player2.size()) {
        recursiveCombat(player1.take(card1), player2.take(card2))
      } else {
        if (card1 > card2) player1 else player2
      }
      when (winner.name) {
        player1.name -> player1.addWinnings(card1, card2)
        player2.name -> player2.addWinnings(card2, card1)
        else -> error("Unknown winner $winner")
      }
    }
    return if (player1.isNotEmpty()) {
      player1.also { check(player2.size() == 0) }
    } else {
      player2.also { check(player1.size() == 0) }
    }
  }

  fun solve(input: Sequence<String>): String {
    val (player1, player2) = parseDecks(input)
    return recursiveCombat(player1, player2).score().toString()
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
