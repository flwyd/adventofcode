// Copyright 2021 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.
//
// https://adventofcode.com/2021/day/23
package main

/* day23 computes the cost to move amphipods from four rooms into their proper
rooms; moves are blocked if there's an amphipod in the way.  Amphipods have
letter-based kinds.  Each space move costs A=1, B=10, C=100, D=1000.
Go implementation because I had trouble finding a bug in my Raku solution,
and each run took tens of minutes.  Board structure is hard-coded for
example and actual input because I didn't want to focus on parsing; this
turned out to be convenient since part 2 added new input. */

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
)

var printWinner = flag.Bool("print-winner", false, "Show winning moves")

func absInt(a int) int {
	if a >= 0 {
		return a
	}
	return -1 * a
}

type Position struct{ hall, room, slot int }

func (p Position) X() int {
	if p.hall > 0 {
		return p.hall
	}
	return p.room
}

func (p Position) dist(o Position) int {
	if p.hall > 0 && p.room > 0 {
		log.Fatalf("Invalid position: %v", p)
	}
	if o.hall > 0 && o.room > 0 {
		log.Fatalf("Invalid position: %v", o)
	}
	if p.hall > 0 && o.room > 0 {
		return absInt(p.hall-o.room) + o.slot
	}
	if o.hall > 0 && p.room > 0 {
		return absInt(o.hall-p.room) + p.slot
	}
	if p.hall > 0 && o.hall > 0 { // not actually a legal move
		return absInt(p.hall - o.hall)
	}
	return absInt(p.room-o.room) + p.slot + o.slot
}

func (p Position) String() string {
	if p.hall > 0 && p.room > 0 {
		log.Fatalf("Invalid position hall %d room %d slot %d", p.hall, p.room, p.slot)
	}
	if p.hall > 0 {
		return fmt.Sprintf("{hall: %d}", p.hall)
	}
	return fmt.Sprintf("{room: %d,slot: %d}", p.room, p.slot)
}

var validHall = []Position{
	Position{hall: 1}, Position{hall: 2}, Position{hall: 4}, Position{hall: 6},
	Position{hall: 8}, Position{hall: 10}, Position{hall: 11},
}

type Amphipod struct {
	kind         byte
	pos          Position
	target, cost int
}

func newAmphipod(kind byte, pos Position) Amphipod {
	a := Amphipod{kind: kind, pos: pos}
	switch kind {
	case 'A':
		a.target = 3
		a.cost = 1
	case 'B':
		a.target = 5
		a.cost = 10
	case 'C':
		a.target = 7
		a.cost = 100
	case 'D':
		a.target = 9
		a.cost = 1000
	}
	return a
}

func (a Amphipod) String() string {
	return fmt.Sprintf("Amphipod{kind: %q, pos: %s, target: %d, cost: %d}", a.kind, a.pos, a.target, a.cost)
}

type BoardKey string
type Board struct {
	pods        []Amphipod
	depth, cost int
}

func newBoard(cost int, depth int, pods ...Amphipod) *Board {
	aps := make([]Amphipod, len(pods))
	copy(aps, pods)
	return &Board{pods: aps, depth: depth, cost: cost}
}

func (b *Board) key() BoardKey {
	parts := make([]string, len(b.pods))
	for i, a := range b.pods {
		parts[i] = a.pos.String()
	}
	return BoardKey(strings.Join(parts, ";"))
}

func (b *Board) validMoves() []*Board {
	res := make([]*Board, 0, 8)
	for i, a := range b.pods {
		if a.pos.room != a.target {
			for j := b.depth; j > 0; j-- {
				p := Position{room: a.target, slot: j}
				if b.validMove(a, p) {
					res = append(res, b.move(i, p))
					break
				}
			}
		}
		if a.pos.room > 0 && (a.pos.room != a.target || !b.roomSatisfied(a.target)) {
			for _, p := range validHall {
				if b.validMove(a, p) {
					res = append(res, b.move(i, p))
				}
			}
		}
	}
	return res
}

func (b *Board) validMove(a Amphipod, p Position) bool {
	ap := a.pos
	if p == ap {
		return false
	}
	if p.hall > 0 && ap.hall > 0 {
		return false
	}
	if p.room > 0 && a.target != p.room {
		return false
	}
	if p.hall == 3 || p.hall == 5 || p.hall == 7 || p.hall == 9 {
		return false // can't stop outside a room
	}
	sawSlot := make([]bool, b.depth+1)
	for _, o := range b.pods {
		if o == a {
			continue
		}
		op := o.pos
		if op == p {
			return false
		}
		if op.hall > 0 {
			if ap.X() < p.X() && ap.X() <= op.X() && op.X() <= p.X() {
				return false
			}
			if ap.X() > p.X() && ap.X() >= op.X() && op.X() >= p.X() {
				return false
			}
		}
		if op.room > 0 && op.room == p.room {
			if o.kind != a.kind {
				return false
			}
			if op.slot < p.slot {
				return false
			}
			sawSlot[op.slot] = true
		}
		if op.room > 0 && op.room == ap.room && op.slot < ap.slot {
			return false
		}
	}
	if p.slot > 0 {
		for i := p.slot + 1; i <= b.depth; i++ {
			if !sawSlot[i] {
				return false
			}
		}
	}
	return true
}

func (b *Board) move(i int, p Position) *Board {
	a := b.pods[i]
	anew := a
	anew.pos = p
	bnew := newBoard(a.cost*a.pos.dist(p)+b.cost, b.depth, b.pods...)
	bnew.pods[i] = anew
	return bnew
}

func (b *Board) satisfied() bool {
	for _, a := range b.pods {
		if a.pos.room != a.target {
			return false
		}
	}
	return true
}

func (b *Board) roomSatisfied(room int) bool {
	for _, a := range b.pods {
		if a.target == room && a.pos.room != a.target {
			return false
		}
	}
	return true
}

func (b *Board) minRemainingCost() int {
	res := 0
	targets := make(map[int][]Amphipod)
	for _, a := range b.pods {
		if _, ok := targets[a.target]; !ok {
			targets[a.target] = make([]Amphipod, 0, 4)
		}
		targets[a.target] = append(targets[a.target], a)
	}
	for t, pods := range targets {
		d := b.depth
		for i := b.depth; i > 0; i-- {
			for _, a := range pods {
				if a.pos.room == t && a.pos.slot == i {
					d--
					break
				}
			}
		}
		if d == 0 {
			continue // room fully satisfied
		}
		dc := d
		for _, a := range pods {
			if a.pos.room != t || a.pos.slot < d {
				res += a.cost * (absInt(a.pos.X()-t) + dc)
				dc--
			}
		}
	}
	return res
}

func (b *Board) String() string {
	lines := make([]string, b.depth+3)
	lines[0] = "#############"
	lines[b.depth+2] = "  #########  "
	hall := []byte{'#', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '#'}
	rooms := make([][]byte, b.depth)
	for i := range rooms {
		rooms[i] = []byte{' ', ' ', '#', '.', '#', '.', '#', '.', '#', '.', '#', ' ', ' '}
	}
	rooms[0] = []byte{'#', '#', '#', '.', '#', '.', '#', '.', '#', '.', '#', '#', '#'}
	for _, p := range b.pods {
		if p.pos.hall > 0 {
			hall[p.pos.hall] = p.kind
		}
		if p.pos.room > 0 {
			rooms[p.pos.slot-1][p.pos.room] = p.kind
		}
	}
	lines[1] = string(hall)
	for i, r := range rooms {
		lines[2+i] = string(r)
	}
	return strings.Join(lines, "\n")
}

func solve(initial *Board) int {
	seen := make(map[BoardKey]int)
	seen[initial.key()] = 0
	parent := make(map[*Board]*Board)
	q := make(map[int][]*Board)
	q[0] = []*Board{initial}
	var pri, seenSkipped int
	for {
		for q[pri] == nil || len(q[pri]) == 0 {
			pri++
			if pri > 1000000 {
				log.Fatalf("Somehow got to cost %d, seen %d boards", pri, len(seen))
			}
		}
		for i := 0; i < len(q[pri]); i++ {
			b := q[pri][i]
			if b.satisfied() {
				log.Printf("Found winner at cost %d with %d seen skipped:\n", pri, seenSkipped)
				if *printWinner {
					for x := b; x != nil; x = parent[x] {
						log.Printf("Cost %d\n%s\n", x.cost, x)
					}
				}
				return b.cost
			}
			for _, m := range b.validMoves() {
				key := m.key()
				rem := m.minRemainingCost()
				if prev, ok := seen[key]; ok && prev <= m.cost+rem {
					seenSkipped++
					continue
				}
				seen[key] = m.cost + rem
				parent[m] = b
				c := m.cost + rem
				if q[c] == nil {
					q[c] = make([]*Board, 0)
				}
				q[c] = append(q[c], m)
			}
		}
		delete(q, pri)
	}
	log.Fatalf("Somehow ran out of boards at cost %d, seen %d boards", pri, len(seen))
	return 0
}

func runPart(part int, initial *Board, expected int, name string) bool {
	fmt.Printf("Running part %d on %s expecting %d\n", part, name, expected)
	start := time.Now()
	res := solve(initial)
	dur := time.Since(start)
	m := "❌"
	if res == expected {
		m = "✓"
	}
	fmt.Printf("%s Part %d on %s got %d in %s\n", m, part, name, res, dur)
	if expected != 0 && res != expected {
		fmt.Printf("❌ got %d but want %d\n\n", res, expected)
		return false
	}
	fmt.Println()
	return true
}

var part1Example = newBoard(0, 2,
	newAmphipod('B', Position{room: 3, slot: 1}), newAmphipod('A', Position{room: 3, slot: 2}),
	newAmphipod('C', Position{room: 5, slot: 1}), newAmphipod('D', Position{room: 5, slot: 2}),
	newAmphipod('B', Position{room: 7, slot: 1}), newAmphipod('C', Position{room: 7, slot: 2}),
	newAmphipod('D', Position{room: 9, slot: 1}), newAmphipod('A', Position{room: 9, slot: 2}),
)

var part1Actual = newBoard(0, 2,
	newAmphipod('C', Position{room: 3, slot: 1}), newAmphipod('B', Position{room: 3, slot: 2}),
	newAmphipod('B', Position{room: 5, slot: 1}), newAmphipod('D', Position{room: 5, slot: 2}),
	newAmphipod('D', Position{room: 7, slot: 1}), newAmphipod('A', Position{room: 7, slot: 2}),
	newAmphipod('A', Position{room: 9, slot: 1}), newAmphipod('C', Position{room: 9, slot: 2}),
)

var part2Example = newBoard(0, 4,
	newAmphipod('B', Position{room: 3, slot: 1}), newAmphipod('D', Position{room: 3, slot: 2}), newAmphipod('D', Position{room: 3, slot: 3}), newAmphipod('A', Position{room: 3, slot: 4}),
	newAmphipod('C', Position{room: 5, slot: 1}), newAmphipod('C', Position{room: 5, slot: 2}), newAmphipod('B', Position{room: 5, slot: 3}), newAmphipod('D', Position{room: 5, slot: 4}),
	newAmphipod('B', Position{room: 7, slot: 1}), newAmphipod('B', Position{room: 7, slot: 2}), newAmphipod('A', Position{room: 7, slot: 3}), newAmphipod('C', Position{room: 7, slot: 4}),
	newAmphipod('D', Position{room: 9, slot: 1}), newAmphipod('A', Position{room: 9, slot: 2}), newAmphipod('C', Position{room: 9, slot: 3}), newAmphipod('A', Position{room: 9, slot: 4}),
)

var part2Actual = newBoard(0, 4,
	newAmphipod('C', Position{room: 3, slot: 1}), newAmphipod('D', Position{room: 3, slot: 2}), newAmphipod('D', Position{room: 3, slot: 3}), newAmphipod('B', Position{room: 3, slot: 4}),
	newAmphipod('B', Position{room: 5, slot: 1}), newAmphipod('C', Position{room: 5, slot: 2}), newAmphipod('B', Position{room: 5, slot: 3}), newAmphipod('D', Position{room: 5, slot: 4}),
	newAmphipod('D', Position{room: 7, slot: 1}), newAmphipod('B', Position{room: 7, slot: 2}), newAmphipod('A', Position{room: 7, slot: 3}), newAmphipod('A', Position{room: 7, slot: 4}),
	newAmphipod('A', Position{room: 9, slot: 1}), newAmphipod('A', Position{room: 9, slot: 2}), newAmphipod('C', Position{room: 9, slot: 3}), newAmphipod('C', Position{room: 9, slot: 4}),
)

func main() {
	var success [4]bool
	success[0] = runPart(1, part1Example, 12521, "input.example.txt")
	success[1] = runPart(1, part1Actual, 13520, "input.actual.txt")
	success[2] = runPart(2, part2Example, 44169, "input.example.txt")
	success[3] = runPart(2, part2Actual, 48708, "input.actual.txt")
	fmt.Printf("Success? %v\n", success)
	for _, s := range success {
		if !s {
			os.Exit(1)
		}
	}
	os.Exit(0)
}
