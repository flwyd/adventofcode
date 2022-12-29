/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec11

import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: grid of floor (.), open (L), occupied (#) seats. Output is number of occupied seats after
 applying rules repeatedly until they stabilize. */

fun List<String>.toCharArrays() = Array(size) { get(it).toCharArray() }

object Part1 {
  fun solve(input: Sequence<String>): String {
    var grid = Grid(input.toList().toCharArrays())
    while (true) {
      val next = grid.evolve()
      if (next === grid) {
        return grid.cells.map { it.count('#'::equals) }.sum().toString()
      }
      grid = next
      // println(grid.cells.map { it.joinToString("") }.joinToString("\n"))
      // println()
    }
  }

  /* If open and adjacent to no closed spots, spot becomes occupied.
  If occupied and adjacent to >= 4 occupied, becomes open. */
  class Grid(val cells: Array<CharArray>) {
    private val height = cells.size
    private val width = cells[0].size

    fun evolve(): Grid {
      val newCells = Array(height) { CharArray(width) }
      var changes = 0
      for (i in 0 until height) {
        for (j in 0 until width) {
          newCells[i][j] = when (cells[i][j]) {
            'L' -> if (countNeighbors(i, j, '#') == 0) '#' else 'L'
            '#' -> if (countNeighbors(i, j, '#') >= 4) 'L' else '#'
            '.' -> '.'
            else -> throw IllegalStateException("Invalid character in $cells")
          }
          if (cells[i][j] != newCells[i][j]) {
            changes++
          }
        }
      }
      return if (changes == 0) this else Grid(newCells)
    }

    private fun countNeighbors(row: Int, col: Int, c: Char): Int {
      var matches = 0
      for (i in ((row - 1)..(row + 1)).intersect(0 until height)) {
        for (j in ((col - 1)..(col + 1)).intersect(0 until width)) {
          if (cells[i][j] == c && (i != row || j != col)) {
            matches++
          }
        }
      }
      return matches
    }
  }
}

object Part2 {
  fun solve(input: Sequence<String>): String {
    var grid = Grid(input.toList().toCharArrays())
    while (true) {
      val next = grid.evolve()
      if (next === grid) {
        return grid.cells.map { it.count('#'::equals) }.sum().toString()
      }
      grid = next
      // println(grid.cells.map { it.joinToString("") }.joinToString("\n"))
      // println()
    }
  }

  /* Decisions are made by line-of-sight.  If open can't see occupied, becomes occupied.
  If occupied and sees >= 5 occupied, becomes open. */
  class Grid(val cells: Array<CharArray>) {
    private val height = cells.size
    private val width = cells[0].size

    fun evolve(): Grid {
      val newCells = Array(height) { CharArray(width) }
      var changes = 0
      for (i in 0 until height) {
        for (j in 0 until width) {
          newCells[i][j] = when (cells[i][j]) {
            'L' -> if (countVisible(i, j, '#') == 0) '#' else 'L'
            '#' -> if (countVisible(i, j, '#') >= 5) 'L' else '#'
            '.' -> '.'
            else -> throw IllegalStateException("Invalid character in $cells")
          }
          if (cells[i][j] != newCells[i][j]) {
            changes++
          }
        }
      }
      return if (changes == 0) this else Grid(newCells)
    }

    private fun countVisible(row: Int, col: Int, c: Char): Int {
      var matches = 0
      for (Δr in -1..1) {
        for (Δc in -1..1) {
          if (Δr != 0 || Δc != 0) {
            var i = row + Δr
            var j = col + Δc
            while (i in 0 until height && j in 0 until width) {
              if (cells[i][j] == c) {
                matches++
                break
              } else if (cells[i][j] != '.') {
                break
              }
              i += Δr
              j += Δc
            }
          }
        }
      }
      return matches
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
