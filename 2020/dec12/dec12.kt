/*
 * Copyright 2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package dec12

import java.lang.Math.floorMod
import java.lang.Math.toDegrees
import java.lang.Math.toRadians
import kotlin.math.absoluteValue
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.time.ExperimentalTime
import kotlin.time.TimeSource
import kotlin.time.measureTimedValue

/* Input: (operation)(number) instructions to move on a Cartesian grid. EWNS move in cardinal
   directions. LR rotate (always increments of 90). F moves in the current direction. */

operator fun Pair<Int, Int>.times(i: Int) = first * i to second * i
operator fun Pair<Int, Int>.plus(p: Pair<Int, Int>) = first + p.first to second + p.second
val Pair<Int, Int>.manhattanDistance get() = first.absoluteValue + second.absoluteValue
val Pair<Int, Int>.crowDistance get() = sqrt(first.toDouble().pow(2) + second.toDouble().pow(2))

val pattern = Regex("""([NSEWLRF])(\d+)""")
val headings = mapOf("E" to (+1 to 0), "W" to (-1 to 0), "N" to (0 to +1), "S" to (0 to -1))

/* Initial state: ship heading east. */
object Part1 {
  fun solve(input: Sequence<String>): String {
    val headingCycle = listOf("N", "W", "S", "E") // counterclockwise, like trig functions
    var heading = "E"
    var position = 0 to 0
    input.map { pattern.matchEntire(it)!!.groups }.map { it[1]!!.value to it[2]!!.value.toInt() }
      .forEach { (op, value) ->
        when (op) {
          in headings -> position += headings.getValue(op) * value
          "F" -> position += headings.getValue(heading) * value
          "L", "R" -> {
            val factor = if (op == "R") -1 else 1
            heading = with(headingCycle) {
              this[floorMod(indexOf(heading) + value * factor / 90, size)]
            }
          }
          else -> throw IllegalStateException("Unknown operation $op$value")
        }
      }
    return position.manhattanDistance.toString()
  }
}

/* Operations are relative to a waypoint. EWNS move the waypoint, F moves ship along waypoint vector
   and LR rotate the vector around the ship. */
object Part2 {
  fun solve(input: Sequence<String>): String {
    var waypoint = 10 to 1 // 10 east, 1 north
    var position = 0 to 0
    input.map { pattern.matchEntire(it)!!.groups }.map { it[1]!!.value to it[2]!!.value.toInt() }
      .forEach { (op, value) ->
        when (op) {
          in headings -> waypoint += headings.getValue(op) * value
          "F" -> position += waypoint * value
          "L", "R" -> {
            val curAngle = toDegrees(atan2(waypoint.second.toDouble(), waypoint.first.toDouble()))
            val angle = toRadians((curAngle + value * (if (op == "R") -1 else 1)) % 360)
            val hypot = waypoint.crowDistance
            waypoint = (hypot * cos(angle)).roundToInt() to (hypot * sin(angle)).roundToInt()
          }
          else -> throw IllegalStateException("Unknown operation $op$value")
        }
      }
    return position.manhattanDistance.toString()
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
