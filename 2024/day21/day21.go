///usr/bin/true; exec /usr/bin/env go run "$0" "`dirname $0`/runner.go" "$@"
// Copyright 2024 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code 2024 day 21 https://adventofcode.com/2024/day/21
//
// Input is five lines with a series of digits followed by an A.  These need to
// be entered in a 789/456/123/_0A keypad which is controlled by several levels
// of indirection of _^A/<v> directional keypads.  The A button on a directional
// means "push the button" and the others move around.  The _ above is a blank
// space that can't be moved to.  In both parts the answer is the length of the
// button sequence that needs to be pressed on a user-controlled keypad which
// controls N layers of directional keypad indirection and then finally the
// numeric keypad.  Part 1 has 2 layers of indirection between the first and
// last keypads, part 2 has 25 layers of indirection.

package main

import (
	"log"
	"math"
	"strconv"
	"strings"
)

type pad map[rune]map[rune][]string

var (
	numpad = pad{
		'A': {
			'7': {"^^^<<A", "<^^^<A"}, '8': {"^^^<A", "<^^^A"}, '9': {"^^^A"},
			'4': {"^^<<A"}, '5': {"^^<A", "<^^A"}, '6': {"^^A"},
			'1': {"^<<A"}, '2': {"^<A", "^<A"}, '3': {"^A"},
			'0': {"<A"}, 'A': {"A"},
		},
		'0': {
			'7': {"^^^<A", "^^^<A"}, '8': {"^^^A"}, '9': {"^^^>A", ">^^^A"},
			'4': {"^^<A"}, '5': {"^^A"}, '6': {"^^>A", ">^^A"},
			'1': {"^<A", "^<A"}, '2': {"^A"}, '3': {"^>A", ">^A"},
			'0': {"A"}, 'A': {">A"},
		},
		'1': {
			'7': {"^^A"}, '8': {"^^>A", ">^^A"}, '9': {"^^>>A", ">>^^A"},
			'4': {"^A"}, '5': {"^>A", ">^A"}, '6': {"^>>A", ">>^A"},
			'1': {"A"}, '2': {">A"}, '3': {">>A"},
			'0': {">vA"}, 'A': {">>vA"},
		},
		'2': {
			'7': {"^^<A", "<^^A"}, '8': {"^^A"}, '9': {"^^>A", ">^^A"},
			'4': {"^<A", "<^A"}, '5': {"^A"}, '6': {"^>A", ">^A"},
			'1': {"<A"}, '2': {"A"}, '3': {">A"},
			'0': {"vA"}, 'A': {">vA", "v>A"},
		},
		'3': {
			'7': {"^^<<A", "<<^^A"}, '8': {"^^<A", "<^^A"}, '9': {"^^A"},
			'4': {"^<<A", "<<^A"}, '5': {"^<A", "<^A"}, '6': {"^A"},
			'1': {"<<A"}, '2': {"<A"}, '3': {"A"},
			'0': {"<vA", "v<A"}, 'A': {"vA"},
		},
		'4': {
			'7': {"^A"}, '8': {"^>A", ">^A"}, '9': {"^>>A", ">>^A"},
			'4': {"A"}, '5': {">A"}, '6': {">>A"},
			'1': {"vA"}, '2': {">vA", "v>A"}, '3': {">>vA", "v>>A"},
			'0': {">vvA"}, 'A': {">>vvA"},
		},
		'5': {
			'7': {"^<A", ">^A"}, '8': {"^A"}, '9': {"^>A", "v^A"},
			'4': {"<A"}, '5': {"A"}, '6': {">A"},
			'1': {"<vA", "v<A"}, '2': {"vA"}, '3': {">vA", "v>A"},
			'0': {"vvA"}, 'A': {">vvA", "vv>A"},
		},
		'6': {
			'7': {"^<<A", "<<^A"}, '8': {"^<A", "<^A"}, '9': {"^A"},
			'4': {"<<A"}, '5': {"<A"}, '6': {"A"},
			'1': {"<<vA", "v<<A"}, '2': {"<vA", "<vA"}, '3': {"vA"},
			'0': {"<vvA", "vv<A"}, 'A': {"vvA"},
		},
		'7': {
			'7': {"A"}, '8': {">A"}, '9': {">>A"},
			'4': {"vA"}, '5': {">vA", "v>A"}, '6': {">>vA", "v>>A"},
			'1': {"vvA"}, '2': {">vvA", "vv>A"}, '3': {">>vvA", "vv>>A"},
			'0': {">vvvA"}, 'A': {">>vvvA"},
		},
		'8': {
			'7': {"<A"}, '8': {"A"}, '9': {">A"},
			'4': {"<vA", "v<A"}, '5': {"vA"}, '6': {">vA", "v>A"},
			'1': {"<vvA", "vv<A"}, '2': {"vvA"}, '3': {">vvA", "vvA"},
			'0': {"vvvA"}, 'A': {">vvvA", "vvv>A"},
		},
		'9': {
			'7': {"<<A"}, '8': {"<A"}, '9': {"A"},
			'4': {"<<vA", "v<<A"}, '5': {"<vA", "v<A"}, '6': {"vA"},
			'1': {"<<vvA", "vv<<A"}, '2': {"<vvA", "vv<A"}, '3': {"vvA"},
			'0': {"<vvvA", "vvv<A"}, 'A': {"vvvA"},
		},
	}

	dirpad = pad{
		'A': {
			'^': {"<A"}, 'A': {"A"},
			'<': {"<v<A", "v<<A"}, 'v': {"<vA", "v<A"}, '>': {"vA"},
		},
		'^': {
			'^': {"A"}, 'A': {">A"},
			'<': {"v<A"}, 'v': {"vA"}, '>': {"v>A", ">vA"},
		},
		'<': {
			'^': {">^A"}, 'A': {">>^A", ">^>A"},
			'<': {"A"}, 'v': {">A"}, '>': {">>A"},
		},
		'v': {
			'^': {"^A"}, 'A': {">^A", "^>A"},
			'<': {"<A"}, 'v': {"A"}, '>': {">A"},
		},
		'>': {
			'^': {"^<A", "<^A"}, 'A': {"^A"},
			'<': {"<<A"}, 'v': {"<A"}, '>': {"A"},
		},
	}

	allpads = []pad{numpad, dirpad, dirpad}
)

type key struct {
	seq   string
	depth int
}

type solver struct {
	pads  []pad
	cache map[key]int
}

// indirection is the number of robot-controlled dirpads
func newSolver(indirection int) *solver {
	pads := []pad{numpad}
	for range indirection {
		pads = append(pads, dirpad)
	}
	return &solver{pads: pads, cache: make(map[key]int)}
}

func (s *solver) sequenceLength(seq string, depth int) int {
	if depth >= len(s.pads) {
		return len(seq)
	}
	k := key{seq, depth}
	if l := s.cache[k]; l != 0 {
		return l
	}
	var total int
	p := s.pads[depth]
	cur := 'A'
	for _, r := range seq {
		l := math.MaxInt
		for _, o := range p[cur][r] {
			l = min(l, s.sequenceLength(o, depth+1))
		}
		total += l
		cur = r
	}
	s.cache[k] = total
	return total
}

func (s *solver) score(nums string) int {
	i, err := strconv.Atoi(strings.ReplaceAll(nums, "A", ""))
	if err != nil {
		log.Fatalf("Invalid numeric keypad entry %q", nums)
	}
	return s.sequenceLength(nums, 0) * i
}

func solve(lines []string, levels int) string {
	s := newSolver(levels)
	var total int
	for _, l := range lines {
		total += s.score(l)
	}
	return strconv.Itoa(total)
}

func part1(lines []string) string {
	return solve(lines, 2)
}

func part2(lines []string) string {
	return solve(lines, 25)
}

func main() {
	runMain(part1, part2)
}

const dayName = "day21"
