//usr/bin/true; exec /usr/bin/env go run "$0" "`dirname $0`/runner.go" "$@"
// Copyright 2024 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code 2024 day 23 https://adventofcode.com/2024/day/23
//
// Input is lines like ab-cd indicating an undirected connection between two
// computers in a network.  Part 1 answer is the number of groups of three
// fully-connected computers where at least one computer name starts with 't'.
// Part 2 answer is the sorted, comma-separated list of computers which form the
// largest fully-connected subcomponent of the network.

package main

import (
	"log"
	"maps"
	"slices"
	"strconv"
	"strings"
)

type stringset map[string]bool

func (s stringset) add(v string) stringset {
	s[v] = true
	return s
}

func (s stringset) remove(v string) stringset {
	delete(s, v)
	return s
}

func (s stringset) contains(v string) bool { return s[v] }

func (s stringset) intersect(o stringset) stringset {
	r := make(stringset)
	for v := range s {
		if o.contains(v) {
			r.add(v)
		}
	}
	return r
}

func (s stringset) tokey() string {
	return strings.Join(slices.Sorted(maps.Keys(s)), ",")
}

type setqueue struct {
	sets    [][]stringset
	biggest int
}

func (q *setqueue) add(s stringset) {
	for len(s) >= len(q.sets) {
		q.sets = append(q.sets, nil)
		q.biggest = len(s)
	}
	q.sets[len(s)] = append(q.sets[len(s)], s)
}

func (q *setqueue) pop() stringset {
	r := q.sets[q.biggest][0]
	q.sets[q.biggest] = q.sets[q.biggest][1:]
	for len(q.sets[q.biggest]) == 0 {
		q.biggest--
		if q.biggest <= 0 {
			log.Fatalf("sequeue is empty: %v", q)
		}
	}
	return r
}

func twokey(a, b string) string {
	return min(a, b) + "," + max(b, a)
}

func fullyConnected(comps map[string]stringset, s stringset) bool {
	for k := range maps.Keys(s) {
		c := comps[k]
		for x := range maps.Keys(s) {
			if x != k && !c.contains(x) {
				return false
			}
		}
	}
	return true
}

func part1(lines []string) string {
	comps := makeComputers(lines)
	seen := make(map[string]bool)
	for a, s := range comps {
		if a[0] == 't' {
			for b := range maps.Keys(s) {
				for c := range maps.Keys(comps[b]) {
					if s.contains(c) {
						seen[make(stringset).add(a).add(b).add(c).tokey()] = true
					}
				}
			}
		}
	}
	return strconv.Itoa(len(seen))
}

func part2(lines []string) string {
	comps := makeComputers(lines)
	var pq setqueue
	seen := make(map[string]bool)
	for k, c := range comps {
		for v := range maps.Keys(c) {
			kk := twokey(k, v)
			if !seen[kk] {
				seen[kk] = true
				s := c.intersect(comps[v])
				s.add(k).add(v)
				pq.add(s)
			}
		}
	}
	// for i := 0; i <= pq.biggest; i++ {
	// 	log.Printf("PQ %d has %d", i, len(pq.sets[i]))
	// }
	for {
		s := pq.pop()
		if fullyConnected(comps, s) {
			return s.tokey()
		}
		for k := range maps.Keys(s) {
			o := maps.Clone(s).remove(k)
			kk := o.tokey()
			if !seen[kk] {
				seen[kk] = true
				pq.add(o)
			}
		}
	}
}

func makeComputers(lines []string) map[string]stringset {
	comps := make(map[string]stringset)
	for _, l := range lines {
		a, b, found := strings.Cut(l, "-")
		if !found {
			log.Fatalf("Invalid input line %q", l)
		}
		if comps[a] == nil {
			comps[a] = make(stringset)
		}
		if comps[b] == nil {
			comps[b] = make(stringset)
		}
		comps[a].add(b)
		comps[b].add(a)
	}
	return comps
}

func main() {
	runMain(part1, part2)
}

const dayName = "day23"
