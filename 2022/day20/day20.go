// Copyright 2022 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.
//
// https://adventofcode.com/2022/day/20

/*
day20 in Go since I could not figure out what was wrong with my Elixir
solution so I figured I'd reimplement it in a different language to see if I
had a hard-to-spot bug.  Turns out it was an unclear specification.
*/
package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"time"
)

func main() {
	for _, arg := range os.Args[1:] {
		fmt.Printf("Reading %s\n", arg)
		f, err := os.Open(arg)
		if err != nil {
			log.Fatalf("Could not open %s: %v", arg, err)
		}
		defer f.Close()
		ints := make([]int, 0, 5000)
		s := bufio.NewScanner(f)
		for s.Scan() {
			var i int
			if _, err := fmt.Sscanf(s.Text(), "%d", &i); err != nil {
				log.Fatalf("Could not parse int %s: %v", s.Text(), err)
			}
			ints = append(ints, i)
		}

		fmt.Printf("Running part1 on %s (%d lines)\n", arg, len(ints))
		start := time.Now()
		res := part1(ints)
		dur := time.Since(start)
		fmt.Printf("part1: %d\n", res)
		fmt.Printf("Finished part1 in %s on %s\n", dur, arg)

		fmt.Printf("Running part2 on %s (%d lines)\n", arg, len(ints))
		start = time.Now()
		res = part2(ints)
		dur = time.Since(start)
		fmt.Printf("part2: %d\n", res)
		fmt.Printf("Finished part2 in %s on %s\n", dur, arg)
	}
}

type Node struct {
	value      int
	prev, next *Node
}

func (n *Node) find(steps int) *Node {
	o := n
	if steps < 0 {
		for i := steps; i < 0; i++ {
			o = o.prev
		}
	} else {
		for i := 0; i < steps; i++ {
			o = o.next
		}
	}
	return o
}

func (n *Node) findValue(v int) *Node {
	o := n
	for o.value != v {
		o = o.next
	}
	return o
}

func (n *Node) move(steps int) {
	if steps == 0 {
		return
	}
	// Remove the current node from the circle first, due to unstated assumptions
	// in the problem description.
	n.prev.next = n.next
	n.next.prev = n.prev
	t := n.find(steps)
	if steps < 0 {
		prev := t.prev
		n.prev = prev
		n.next = t
		t.prev = n
		prev.next = n
	} else {
		next := t.next
		n.next = next
		n.prev = t
		t.next = n
		next.prev = n
	}
}

func (n *Node) toSlice() []int {
	ints := make([]int, 0, 5000)
	ints = append(ints, n.value)
	for o := n.next; o != n; o = o.next {
		ints = append(ints, o.value)
	}
	return ints
}

func part1(ints []int) int {
	size := len(ints)
	nodes := buildList(ints, 1)
	for _, n := range nodes {
		n.move(n.value % (size - 1))
	}
	return score(nodes)
}

const part2Multiplier = 811589153

func part2(ints []int) int {
	size := len(ints)
	nodes := buildList(ints, part2Multiplier)
	for i := 0; i < 10; i++ {
		for _, n := range nodes {
			steps := n.value % (size - 1)
			n.move(steps)
		}
	}
	return score(nodes)
}

func buildList(ints []int, multiplier int) []*Node {
	size := len(ints)
	nodes := make([]*Node, 0, size)
	for _, i := range ints {
		n := &Node{value: i * multiplier}
		if len(nodes) > 0 {
			n.prev = nodes[len(nodes)-1]
			nodes[len(nodes)-1].next = n
		}
		nodes = append(nodes, n)
	}
	nodes[0].prev = nodes[size-1]
	nodes[size-1].next = nodes[0]
	return nodes
}

func score(nodes []*Node) int {
	zero := nodes[0].findValue(0)
	one := zero.find(1000)
	two := one.find(1000)
	three := two.find(2000)
	return one.value + two.value + three.value
}
