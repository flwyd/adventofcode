//usr/bin/true; exec /usr/bin/env go run "$0" "`dirname $0`/runner.go" "$@"
// Copyright 2025 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code 2025 day 10
// Read the puzzle at https://adventofcode.com/2025/day/10
//
// This file contains code that got answers to most lines of my input,
// but was very slow about it.  This is preserved for some interesting code,
// but day10.go should be used unless you want to wait for a very long time.
//
// Input is a light pattern in square brackets, a series of button lists in
// parentheses, and a list of target joltages in curly braces, e.g.
// [.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
// Button numbers are all 0 to 9, . means off # means on.
// In part 1, buttons toggle lights of the corresponding index, the answer is
// the minimum number of button presses to reach the desired pattern.
// In part 2, buttons increase the joltage level at each given index, the
// answer is the minimum number of button presses to reach the desired levels.
package main

import (
	"context"
	"log"
	"math/bits"
	"sort"
	"strconv"
	"strings"
	"time"
)

type button uint

func (b button) size() int { return bits.OnesCount(uint(b)) }

func (b button) flipsAny(u uint) bool { return bits.OnesCount(uint(b)&u) > 0 }

func (b button) flip(u uint) uint { return uint(b) ^ u }

func (b button) has(i int) bool { return uint(b)&(1<<i) != 0 }

func (b button) String() string {
	if buttonStrings[b] == "" {
		var s strings.Builder
		remaining := b.size()
		for i := 0; remaining > 0; i++ {
			if b.has(i) {
				s.WriteByte('#')
				remaining--
			} else {
				s.WriteByte('.')
			}
		}
		buttonStrings[b] = s.String()
	}
	return buttonStrings[b]
}

var buttonStrings = map[button]string{}

type machine struct {
	desired uint
	Buttons []button
	joltage []int
	num     int
	shape   string
}

func bruteParseMachine(line string) machine {
	var m machine
	words := strings.Fields(line)
	first := words[0]
	m.shape = first[1 : len(words[0])-1]
	for i, c := range first[1 : len(first)-1] {
		if c == '#' {
			m.desired |= 1 << i
		}
	}
	for _, w := range words[1 : len(words)-1] {
		m.Buttons = append(m.Buttons, bruteParseButton(w))
	}
	last := words[len(words)-1]
	for _, s := range strings.Split(last[1:len(last)-1], ",") {
		i, err := strconv.Atoi(s)
		if err != nil {
			log.Fatalf("Non-numeric joltage in %s", last)
		}
		m.joltage = append(m.joltage, i)
	}
	return m
}

func bruteParseButton(word string) button {
	var b button
	for _, s := range strings.Split(word[1:len(word)-1], ",") {
		i, err := strconv.Atoi(s)
		if err != nil {
			log.Fatalf("Non-integer button in %s", word)
		}
		b |= 1 << i
	}
	return b
}

type state struct {
	depth   int
	current uint
	m       *machine
}

func (s state) found() bool { return s.current == s.m.desired }

func (s state) worthPressing(b button) bool { return b.flipsAny(s.current ^ s.m.desired) }

func (s state) press(b button) state {
	return state{depth: s.depth + 1, current: b.flip(s.current), m: s.m}
}

func bruteNumPressesPart1(m machine) int {
	// This is actually a little faster than the day10.go implementation,
	// the latter is a bit simpler.
	seen := map[uint]bool{0: true}
	q := make([]state, 1, 1024)
	q[0] = state{m: &m}
	var steps int
	for {
		if len(q) == 0 {
			log.Fatalf("Queue empty!")
		}
		steps++
		cur := q[0]
		q = q[1:]
		if cur.found() {
			return cur.depth
		}
		for _, b := range cur.m.Buttons {
			if cur.worthPressing(b) {
				s := cur.press(b)
				if !seen[s.current] {
					seen[s.current] = true
					q = append(q, s)
				}
			}
		}
	}
}

type joltageState struct {
	depth   int
	current []int
}

func (s joltageState) found(desired []int) bool {
	for i := range desired {
		if s.current[i] != desired[i] {
			return false
		}
	}
	return true
}

func (s joltageState) priority(desired []int) int {
	sum := 0
	for i := range desired {
		sum += desired[i] - s.current[i]
	}
	return sum
}

func (s joltageState) overflows(desired []int) bool {
	for i := range desired {
		if s.current[i] > desired[i] {
			return true
		}
	}
	return false
}

func (s joltageState) factors(desired []int) []joltageState {
	var res []joltageState
	if s.depth == 0 {
		return res
	}
	for f := 2; ; f++ {
		n := joltageState{depth: s.depth * f, current: make([]int, len(s.current))}
		for i, c := range s.current {
			n.current[i] = c * f
		}
		if n.overflows(desired) {
			break
		}
	}
	return res
}

func (s joltageState) factor(desired []int) int {
	for i := range desired {
		if s.current[i] == 0 || desired[i]%s.current[i] != 0 {
			return 0
		}
		if desired[i]/s.current[i] != desired[0]/s.current[0] {
			return 0
		}
	}
	return desired[0] / s.current[0]
}

func (s joltageState) worthPressing(desired []int, b button) bool {
	var target int
	for i := range desired {
		if b.has(i) && desired[i] <= s.current[i] {
			return false
		}
		target = max(target, desired[i]-s.current[i])
	}
	for i := range desired {
		if b.has(i) && desired[i]-s.current[i] == target {
			return true
		}
	}
	return false
}

func (s joltageState) press(b button) joltageState {
	j := joltageState{depth: s.depth + 1, current: make([]int, len(s.current))}
	copy(j.current, s.current)
	for i := range s.current {
		if b.has(i) {
			j.current[i]++
		}
	}
	return j
}

func (s joltageState) multiPress(b button, desired []int) []joltageState {
	var res []joltageState
	prev := s
	for {
		next := prev.press(b)
		if next.overflows(desired) {
			break
		}
		res = append(res, next)
		prev = next
	}
	return res
}

func bruteNumPressesPart2(ctx context.Context, m machine) int {
	sort.SliceStable(m.Buttons, func(i, j int) bool { return m.Buttons[i].size() > m.Buttons[j].size() })
	initial := joltageState{current: make([]int, len(m.joltage))}
	initialPri := initial.priority(m.joltage)
	var initialKey [10]int
	copy(initialKey[:], initial.current)
	seen := map[[10]int]int{initialKey: 0}
	pq := make([][]joltageState, initialPri+1)
	pq[initialPri] = []joltageState{initial}
	var steps int
	prevPri := initialPri
	for {
		for pri, q := range pq {
			if len(q) == 0 {
				continue
			}
			select {
			case <-ctx.Done():
				guess := pri + q[0].depth
				log.Printf("%d: timeout expired with %d joltage remaining, worst case is %d", m.num, pri, guess)
				return guess
			default: // proceed with the loop
			}
			if pri == 0 {
				best := q[0].depth
				for _, s := range q {
					best = min(best, s.depth)
				}
				log.Printf("%d %v found depth %d after %d steps queue %d seen %d", m.num, m.joltage, best, steps, len(q), len(seen))
				return best
			}
			if prevPri > pri {
				log.Printf("%d %v priority %d steps %d queue %d depth %d %v", m.num, m.joltage, pri, steps, len(q), q[0].depth, q[0])
				prevPri = pri
			}
			pq[pri] = nil
			for _, cur := range q {
				steps++
				for _, s := range cur.factors(m.joltage) {
					var key [10]int
					copy(key[:], s.current)
					if d, ok := seen[key]; !ok || d < s.depth {
						seen[key] = s.depth
						p := s.priority(m.joltage)
						pq[p] = append(pq[p], s)
					}
				}
				for _, b := range m.Buttons {
					if cur.worthPressing(m.joltage, b) {
						s := cur.press(b)
						var key [10]int
						copy(key[:], s.current)
						if d, ok := seen[key]; !ok || d < s.depth {
							seen[key] = s.depth
							p := s.priority(m.joltage)
							pq[p] = append(pq[p], s)
						}
					}
				}
			}
		}
	}
}

func brutePart1(lines []string) string {
	var machines []machine
	for i, l := range lines {
		m := bruteParseMachine(l)
		m.num = i + 1
		machines = append(machines, m)
	}
	var sum int
	for _, m := range machines {
		x := bruteNumPressesPart1(m)
		// log.Printf("%d: size %d buttons %d best %d", m.num, len(m.joltage), len(m.Buttons), x)
		sum += x
	}
	return strconv.Itoa(sum)
}

func brutePart2(lines []string) string {
	var machines []machine
	for i, l := range lines {
		m := bruteParseMachine(l)
		m.num = i + 1
		machines = append(machines, m)
	}
	var sum int
	for _, m := range machines {
		func() {
			ctx, cancel := context.WithTimeout(context.Background(), maxMachineTime)
			defer cancel()
			x := bruteNumPressesPart2(ctx, m)
			log.Printf("%d: best %d joltage %v from %d buttons", m.num, x, m.joltage, len(m.Buttons))
			sum += x
		}()
	}
	return strconv.Itoa(sum)
}

var maxMachineTime = 45 * time.Minute

func main() {
	runMain(brutePart1, brutePart2)
}

const dayName = "day10"
