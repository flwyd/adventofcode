///usr/bin/true; exec /usr/bin/env go run "$0" "`dirname $0`/runner.go" "$@"
// Copyright 2024 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code 2024 day 16 https://adventofcode.com/2024/day/16
//
// Input is a grid surrounded by a wall.  # marks walls, . marks open spaces,
// S and E mark start and end.  Part 1 answer is the length of a shortest path
// from S to E.  Part 2 is the number of squares that are part of any shortest
// path.

package main

import (
	"fmt"
	"log"
	"strings"
)

const (
	dot  = '.'
	end  = 'E'
	wall = '#'
)

type direction struct{ row, col int }
type position struct{ row, col int }

var (
	east       = direction{col: 1}
	south      = direction{row: 1}
	west       = direction{col: -1}
	north      = direction{row: -1}
	directions = []direction{east, south, west, north}
)

func (d direction) turnright() direction {
	switch d {
	case east:
		return south
	case south:
		return west
	case west:
		return north
	case north:
		return east
	default:
		log.Fatalf("unknown direction %v", d)
		return d
	}
}

func (d direction) turnleft() direction {
	switch d {
	case east:
		return north
	case north:
		return west
	case west:
		return south
	case south:
		return east
	default:
		log.Fatalf("unknown direction %v", d)
		return d
	}
}

func (p position) move(dir direction) position {
	return position{row: p.row + dir.row, col: p.col + dir.col}
}

type state struct {
	pos position
	dir direction
}

func (s state) possible() (straight, left, right state) {
	straight = state{pos: s.pos.move(s.dir), dir: s.dir}
	left = state{pos: s.pos, dir: s.dir.turnleft()}
	right = state{pos: s.pos, dir: s.dir.turnright()}
	return
}

type provenance struct {
	cost    int
	parents []state
}

func (p *provenance) maybeAdd(parent state, cost int) {
	if p.cost > cost {
		p.cost = cost
		p.parents = []state{parent}
	} else if p.cost == cost {
		p.parents = append(p.parents, parent)
	}
}

type solver struct {
	grid     []string
	pq       map[int][]state
	cheapest int
	highest  int
	end      state
	visited  map[state]int
	prov     map[state]*provenance
}

func (s *solver) add(v, prev state, cost int) {
	if cost < s.cheapest {
		log.Fatalf("Trying to add %v at cost %d but cheapest is %d", v, cost, s.cheapest)
	}
	p := s.prov[v]
	if p == nil {
		p = &provenance{cost: cost}
		s.prov[v] = p
	}
	p.maybeAdd(prev, cost)
	if c, ok := s.visited[v]; !ok || cost < c {
		s.visited[v] = cost
		s.pq[cost] = append(s.pq[cost], v)
		if cost > s.highest {
			s.highest = cost
		}
	}
}

func (s *solver) printgrid() {
	g := make([][]byte, len(s.grid))
	for r, l := range s.grid {
		g[r] = []byte(strings.Clone(l))
	}
	q := []state{s.end}
	var zero state
	for len(q) > 0 {
		v := q[0]
		q = q[1:]
		if v != zero {
			q = append(q, s.prov[v].parents...)
		}
		var d byte
		switch v.dir {
		case east:
			d = '>'
		case west:
			d = '<'
		case north:
			d = '^'
		case south:
			d = 'v'
		}
		g[v.pos.row][v.pos.col] = d
	}
	for _, l := range g {
		fmt.Println(string(l))
	}
}

func (s *solver) pop(cost int) state {
	v := s.pq[cost][0]
	s.pq[cost] = s.pq[cost][1:]
	return v
}

func (s *solver) lookup(p position) byte { return s.grid[p.row][p.col] }

func (s *solver) isend(p position) bool { return s.lookup(p) == end }

func (s *solver) isopen(p position) bool { return s.lookup(p) != wall }

func solve(grid []string, start state) *solver {
	s := &solver{grid: grid, pq: map[int][]state{}, visited: map[state]int{}, prov: map[state]*provenance{}}
	s.add(start, state{}, 0)
	for {
		for len(s.pq[s.cheapest]) == 0 {
			if s.cheapest > s.highest {
				log.Fatalf("Ran out of priority queue: %d > %d", s.cheapest, s.highest)
			}
			s.cheapest++
		}
		v := s.pop(s.cheapest)
		if s.isend(v.pos) {
			s.end = v
			return s
		}
		straight, left, right := v.possible()
		if s.isopen(straight.pos) {
			s.add(straight, v, s.cheapest+1)
		}
		if s.isopen(left.pos) {
			s.add(left, v, s.cheapest+1000)
		}
		if s.isopen(right.pos) {
			s.add(right, v, s.cheapest+1000)
		}
	}
}

func part1(lines []string) string {
	start := state{pos: position{row: len(lines) - 2, col: 1}, dir: east}
	if lines[start.pos.row][start.pos.col] != 'S' {
		start = state{pos: position{row: 1, col: len(lines[0]) - 2}, dir: south}
	}
	s := solve(lines, start)
	s.printgrid()
	return fmt.Sprintf("%d", s.cheapest)
}

func part2(lines []string) string {
	start := state{pos: position{row: len(lines) - 2, col: 1}, dir: east}
	if lines[start.pos.row][start.pos.col] != 'S' {
		start = state{pos: position{row: 1, col: len(lines[0]) - 2}, dir: south}
	}
	s := solve(lines, start)
	// s.printgrid()
	seen := make(map[position]bool)
	q := []state{s.end}
	var zero state
	for len(q) > 0 {
		v := q[0]
		q = q[1:]
		if v != zero {
			seen[v.pos] = true
			q = append(q, s.prov[v].parents...)
		}
	}
	return fmt.Sprintf("%d", len(seen))
}

func main() {
	runMain(part1, part2)
}

const dayName = "day16"
