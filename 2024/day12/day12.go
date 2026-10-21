///usr/bin/true; exec /usr/bin/env go run "$0" "`dirname $0`/runner.go" "$@"
// Copyright 2024 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

package main

func part1(lines []string) string {
	return "TODO"
}

func part2(lines []string) string {
	return "TODO"
}

func main() {
	runMain(part1, part2)
}

const dayName = "day12"

type direction complex128

func (d direction) deosil() direction      { return d * -1i }
func (d direction) widdershins() direction { return d * +1i }

const (
	dirUp    = direction(-1 + 0i)
	dirDown  = direction(1 + 0i)
	dirLeft  = direction(0 - 1i)
	dirRight = direction(0 + 1i)
)

type position complex128

const nowhere = position(-1 - 1i)

func (p position) row() int                  { return int(real(p)) }
func (p position) col() int                  { return int(imag(p)) }
func (p position) move(d direction) position { return p + position(d) }
func (p position) to(o position) direction   { return direction(p - o) }

func inBounds[V any](grid [][]V, p position) bool {
	return p.row() >= 0 && p.row() < len(grid) && p.col() >= 0 && p.col() < len(grid[0])
}

func getOr[V any](grid [][]V, p position, def V) V {
	if !inBounds(grid, p) {
		return def
	}
	return grid[p.row()][p.col()]
}

type edge struct {
	pos position
	dir direction
}

type region struct {
	id      int
	char    rune
	members []position
	edges   []edge
}
