//usr/bin/true; exec /usr/bin/env go run "$0" "`dirname $0`/runner.go" "$@"
// Copyright 2025 Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code 2025 day 10
// Read the puzzle at https://adventofcode.com/2025/day/10
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
	"fmt"
	"log"
	"math/bits"
	"sort"
	"strconv"
	"strings"
)

type machine struct {
	desired uint
	buttons []uint
	joltage []int
	num     int
}

func parseMachine(line string) machine {
	var m machine
	words := strings.Fields(line)
	first := words[0]
	for i, c := range first[1 : len(first)-1] {
		if c == '#' {
			m.desired |= 1 << i
		}
	}
	for _, w := range words[1 : len(words)-1] {
		m.buttons = append(m.buttons, parseButton(w))
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

func parseButton(word string) uint {
	var b uint
	for _, s := range strings.Split(word[1:len(word)-1], ",") {
		i, err := strconv.Atoi(s)
		if err != nil {
			log.Fatalf("Non-integer button in %s", word)
		}
		b |= 1 << i
	}
	return b
}

func machinePresses1(m machine) int {
	type pressState struct{ pressed, set uint }
	if m.desired == 0 {
		return 0
	}
	var initial pressState
	prev := []pressState{initial}
	for {
		var cur []pressState
		for _, s := range prev {
			for i, b := range m.buttons {
				if s.pressed&(1<<i) == 0 {
					t := pressState{pressed: s.pressed | (1 << i), set: s.set ^ b}
					if t.set == m.desired {
						return bits.OnesCount(t.pressed)
					}
					cur = append(cur, t)
				}
			}
		}
		prev = cur
	}
}

func part1(lines []string) string {
	var machines []machine
	for i, l := range lines {
		m := parseMachine(l)
		m.num = i
		machines = append(machines, m)
	}
	var sum int
	for _, m := range machines {
		x := machinePresses1(m)
		// log.Printf("%d: size %d buttons %d best %d", m.num, len(m.joltage), len(m.buttons), x)
		sum += x
	}
	return strconv.Itoa(sum)
}

type matrix [][]int

func newMatrix(rows, cols int) matrix {
	m := make([][]int, rows)
	for i := range rows {
		m[i] = make([]int, cols)
	}
	return m
}

func (m matrix) String() string {
	var b strings.Builder
	for i, r := range m {
		if i > 0 {
			b.WriteRune('\n')
		}
		for j, c := range r {
			if j > 0 {
				b.WriteRune('\t')
			}
			b.WriteString(strconv.Itoa(c))
		}
	}
	return b.String()
}

func (m matrix) rows() int { return len(m) }
func (m matrix) cols() int { return len(m[0]) }

func (m matrix) swap(i, j int) matrix {
	n := make(matrix, m.rows())
	copy(n, m)
	n[i], n[j] = m[j], m[i]
	return n
}

func (m matrix) colswap(a, b int) matrix {
	n := newMatrix(m.rows(), m.cols())
	for i := range n {
		copy(n[i], m[i])
		n[i][a], n[i][b] = n[i][b], n[i][a]
	}
	return n
}

func (m matrix) negate(i int) matrix {
	n := make(matrix, m.rows())
	copy(n, m)
	n[i] = make([]int, m.cols())
	for c := range m.cols() {
		n[i][c] = m[i][c] * -1
	}
	return n
}

func (m matrix) add(dest, src, factor int) matrix {
	n := make(matrix, m.rows())
	copy(n, m)
	n[dest] = make([]int, m.cols())
	for c := range m.cols() {
		n[dest][c] = m[dest][c] + m[src][c]*factor
	}
	return n
}

func (m matrix) rightmost(row int) int {
	for i := m.cols() - 1; i >= 0; i-- {
		if m[row][i] != 0 {
			return i
		}
	}
	return -1
}

type freevars struct {
	vars map[int]bool
	vals [13]int
}

func (f freevars) set(i int) bool { return f.vars[i] }

func (f freevars) numset() int { return len(f.vars) }

func (f freevars) successors(m matrix, worst int, seen map[[13]int]bool) []freevars {
	res := make([]freevars, 0, f.numset())
	if sumSlice(f.vals[:]) >= worst {
		return res
	}
	for i := range f.vars {
		ok := false
		allneg := true
		for _, r := range m {
			if r[i] != 0 {
				v := r[len(r)-1]
				for c := 0; c < m.cols()-1; c++ {
					v -= r[c] * f.vals[c]
				}
				u := v - r[i]
				if absInt(v) > absInt(u) {
					ok = true
				}
				if r[i] > 0 && r[len(r)-1] > 0 {
					// If free variable factors are all negative, total may need to
					// "get worse" before getting more promising
					allneg = false
				}
			}
		}
		if !ok && !allneg {
			continue
		}
		x := freevars{vars: f.vars, vals: f.vals}
		x.vals[i]++
		if seen[x.vals] {
			continue
		}
		res = append(res, x)
	}
	return res
}

func (f freevars) backSubstitute(m matrix) (sum, rem int, ok bool) {
	ok = true
	all := f.vals
	for r := m.rows() - 1; r >= 0; r-- {
		v := m[r][m.cols()-1]
		for c := m.cols() - 2; c > r; c-- {
			v -= all[c] * m[r][c]
		}
		// need to handle rows > columns
		if r > m.cols()-1 || m[r][r] == 0 {
			if v != 0 {
				rem += absInt(v)
				ok = false
			}
		} else {
			if v < 0 {
				ok = false
				rem += -1 * v
			}
			if v%m[r][r] == 0 {
				all[r] = v / m[r][r]
			} else {
				ok = false
			}
		}
	}
	sum = sumSlice(all[:])
	return
}

func reduce(m matrix) matrix {
	/* Inspired by the Hermite Normal Form approach to integer linera programming
	but we don't need to carry the transformation matrix through, just do
	similar reduction operations, which differ from real-valued operations
	used in Gauss-Jordan elimination.  For more on HNF, see
	https://math.stackexchange.com/questions/4500455/to-compute-hermite-normal-form-h-and-u
	https://sites.math.rutgers.edu/~sk1233/courses/ANT-F14/lec3.pdf and lec4.pdf
	https://cseweb.ucsd.edu/classes/fa17/cse206A-a/lec4.pdf */
	col := 0
outer:
	for col < minInt(m.rows(), m.cols()) {
		for i := col + 1; i < m.rows(); i++ {
			if m[col][col] == 0 && m[i][col] != 0 {
				m = m.swap(col, i)
			} else if m[i][col] != 0 && absInt(m[i][col]) < absInt(m[col][col]) {
				m = m.swap(col, i)
			}
		}
		if m[col][col] == 0 {
			for c := col + 1; c < m.cols()-1; c++ {
				if m[col][c] != 0 {
					m = m.colswap(col, c)
					continue outer
				}
			}
		}
		if m[col][col] == 0 {
			// try to put an all-zero row in redundant columns
			for i := col; i < m.rows(); i++ {
				if m.rightmost(i) == -1 {
					if i != col {
						m = m.swap(col, i)
					}
					break
				}
			}
			col++
			continue
		}
		if m[col][col] < 0 {
			m = m.negate(col)
		}
		for i := range m.rows() {
			if i == col {
				continue
			}
			if m[i][col] != 0 {
				factor := m[i][col] / m[col][col]
				m = m.add(i, col, factor*-1)
				if i > col && m[i][col] != 0 {
					continue outer // cur doesn't evenly divide, might need to swap
				}
			}
		}
		col++
	}
	return m
}

func machinePart2(x machine) int {
	buts := make([]uint, len(x.buttons))
	copy(buts, x.buttons)
	sort.SliceStable(buts, func(i, j int) bool {
		return bits.OnesCount(buts[i]) > bits.OnesCount(buts[j])
	})
	numrows := len(x.joltage)
	numcols := len(buts) + 1
	m := newMatrix(numrows, numcols)
	for i := range x.joltage {
		for j, b := range buts {
			if b&(1<<i) != 0 {
				m[i][j] = 1
			}
		}
	}
	for i, v := range x.joltage {
		m[i][numcols-1] = v
	}
	sort.SliceStable(m, func(i, j int) bool {
		var a, b int
		for c := 0; c < numcols-1; c++ {
			a += m[i][c]
			b += m[j][c]
		}
		if a == b {
			return m[i][numcols-1] < m[j][numcols-1]
		}
		return a < b
	})
	// log.Printf("%d: reducing matrix\n%s", x.num, m)
	m = reduce(m)
	// log.Printf("%d: reduced system of equations:\n%s\n%s", x.num, m, sys)
	initial := freevars{vars: map[int]bool{}}
	for i := range m.cols() - 1 {
		if i >= m.rows() || m[i][i] == 0 {
			initial.vars[i] = true
		}
	}
	initsum, initrem, initok := initial.backSubstitute(m)
	if initial.numset() == 0 {
		if initok && initrem == 0 {
			return initsum
		}
		panic(fmt.Sprintf("no freevars sum=%d rem=%d ok=%t free=%+v", initsum, initrem, initok, initial))
	}
	worst := sumSlice(x.joltage)
	best := worst
	if initok && initrem == 0 {
		best = initsum
	}
	seen := map[[13]int]bool{initial.vals: true}
	q := make([]freevars, 0, 1024)
	q = append(q, initial)
	for len(q) != 0 {
		cur := q[0]
		q = q[1:]
		for _, f := range cur.successors(m, worst, seen) {
			seen[f.vals] = true
			sum, rem, ok := f.backSubstitute(m)
			if ok && rem == 0 {
				// log.Printf("%d: possible %d with %v", x.num, sum, f.vals)
				best = minInt(best, sum)
			}
			if sum < worst && sumSlice(f.vals[:]) < best {
				q = append(q, f)
			}
		}
	}
	if best == worst {
		log.Printf("%d: UNLIKELY!!! best==worst %d", x.num, best)
	}
	return best
}

func part2(lines []string) string {
	var machines []machine
	for i, l := range lines {
		m := parseMachine(l)
		m.num = i + 1
		machines = append(machines, m)
	}
	var sum, skipped int
	for _, m := range machines {
		// log.Printf("%d: %d buttons %d joltages %d total joltage", m.num, len(m.buttons), len(m.joltage), sumSlice(m.joltage))
		// start := time.Now()
		x := machinePart2(m)
		// dur := time.Now().Sub(start)
		// log.Printf("%d: best %d after %s", m.num, x, dur)
		sum += x
	}
	if skipped > 0 {
		defer log.Fatalf("Got %d but skipped %d", sum, skipped)
	}
	return strconv.Itoa(sum)
}

func absInt(i int) int {
	if i < 0 {
		return -1 * i
	}
	return i
}

func maxInt(a, b int) int {
	if a >= b {
		return a
	}
	return b
}

func minInt(a, b int) int {
	if a <= b {
		return a
	}
	return b
}

func sumSlice(s []int) int {
	sum := 0
	for _, v := range s {
		sum += v
	}
	return sum
}

func main() {
	runMain(part1, part2)
}

const dayName = "day10"
