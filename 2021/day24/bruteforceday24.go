// Copyright 2021 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// https://adventofcode.com/2021/day/24
// Finds the maximum/minimum 14-digit numbers with no 0s which result in a
// progam with 4 registers and a limited set of opcodes to produce a 0 value in
// the z register at the end of the program.  Depends on a generated function
// named Compute_inputactual (because I name my AoC input file
// input.actual.txt) which is produced by genday24.go.
package main

import (
	"context"
	"fmt"
	"log"
	"math"
	"os"
	"strings"
	"time"
)

type Input [14]int

func NewInput(val int) Input {
	if val < 0 {
		panic(fmt.Errorf("Negative input value: %d (%s)", val, NewInput(-1*val)))
	}
	v := Input{}
	d := val
	for i := 1; i <= 14; i++ {
		v[14-i] = (d % 9) + 1
		d /= 9
	}
	return v
}

func (v Input) Int() int {
	r := 0
	for i := 0; i < 14; i++ {
		r *= 9
		r += (v[i] - 1)
	}
	return r
}

func (v Input) String() string {
	s := [14]string{}
	for i := 0; i < 14; i++ {
		s[i] = fmt.Sprintf("%d", v[i])
	}
	return strings.Join(s[:], "")
}

type Range struct{ min, max int }

func (r Range) String() string {
	min := r.min
	max := r.max
	if r.min < 0 {
		max = -1 * r.min
		min = -1 * r.max
	}
	return fmt.Sprintf("%s..%s", NewInput(min), NewInput(max))
}

func MaybeNegativeRange(min, max int) Range {
	if min > max {
		return Range{min: max, max: min}
	}
	return Range{min: min, max: max}
}

// searchRange iterates through a range of input values.  If it finds an input
// accepted by the problem program it sends it to the out channel and returns.
// If all inputs in the range are invalid it sends the range to the empty
// channel.  It checks for context cancellation before checking each input.
func searchRange(ctx context.Context, r Range, factor int, out chan<- Input, empty chan<- Range) {
	for i := r.max; i >= r.min; i-- {
		select {
		case <-ctx.Done():
			return
		default:
			input := NewInput(factor * i)
			z, _ := Compute_inputactual(input)
			if z == 0 {
				log.Printf("Found z=0 for %s in range %s", input, r)
				select {
				case out <- input:
					return
				case <-ctx.Done():
					return
				}
			}
		}
	}
	log.Printf("Found no z=0 inputs in range %s", r)
	empty <- r
}

const numWorkers = 10 // I happen to have a 12-CPU workstation

// scanRange splits the range min..max into sub-ranges and dispatches each to a
// goroutine which searches the whole range.  The first time a valid input is
// found, all workers are cancelled and the range between the found input and
// the max are scanned.  If the right workers have completed their range, the
// new max will be reduced, but this rarely helps since workers generally all
// finish at roughly the same time, assuming numWorkes < num CPUs.  The factor
// parameter can be 1 to find the maximum valid input or -1 to find the minimum
// input.
func scanRange(ctx context.Context, min, max, factor int) *Input {
	if factor != 1 && factor != -1 {
		panic(fmt.Errorf("Expected factor to be 1 or -1, not %d", factor))
	}
	log.Printf("Scanning %s\n", Range{min: min, max: max})
	valid := make(chan Input)
	empty := make(chan Range)
	empties := make([]Range, 0, numWorkers)
	ctxchild, cancel := context.WithCancel(ctx)
	var expected int
	if (max - min) <= numWorkers {
		expected = 1
		go searchRange(ctxchild, MaybeNegativeRange(factor*min, factor*max), factor, valid, empty)
	} else {
		expected = numWorkers
		size := (max - min) / numWorkers
		for i := 0; i < numWorkers; i++ {
			r := MaybeNegativeRange(factor*(max-size*i), factor*(max-size*(i+1)+1))
			go searchRange(ctxchild, r, factor, valid, empty)
		}
	}
	var found *Input
	for expected > 0 {
		select {
		case v := <-valid:
			cancel()
			found = &v
			expected = 0
		case r := <-empty:
			expected--
			empties = append(empties, r)
		}
	}
	cancel()
	close(valid)
	close(empty)
	if found == nil {
		log.Printf("Found nothing in %d..%d\n", min, max)
		return nil
	}
	if factor == 1 {
		min = found.Int() + 1
	outermax:
		for {
			for _, r := range empties {
				if r.max == max {
					max = r.min - 1
					continue outermax
				}
			}
			break outermax
		}
	} else {
		max = found.Int() - 1
	outermin:
		for {
			for _, r := range empties {
				if r.min == min {
					min = r.max + 1
					continue outermin
				}
			}
			break outermin
		}
	}
	better := scanRange(ctx, min, max, factor)
	if better == nil {
		log.Printf("Found %s in %d..%d", *found, min, max)
		return found
	}
	log.Printf("Found %s better than %s in %d..%d", *better, *found, min, max)
	return better
}

// part1 prints the maximum valid input for the program.
func part1() {
	start := time.Now()
	var winner *Input
	for i := 13; i >= 0; i-- {
		var high, low Input
		for j := 0; j < i; j++ {
			high[j] = 9
			low[j] = 9
		}
		for j := i; j < 14; j++ {
			high[j] = 9
			low[j] = 1
		}
		high[i] = 8
		winner = scanRange(context.Background(), low.Int(), high.Int(), 1)
		if winner != nil {
			break
		}
	}
	dur := time.Since(start)
	if winner == nil {
		fmt.Println("❌ Part 1 has no winners!!! 😦")
	} else {
		fmt.Printf("✓ Part 1 found winner: %s in %s\n", winner, dur)
	}
}

// part2 prints the minimum valid input for the program.
func part2() {
	start := time.Now()
	var winner *Input
	for i := 13; i >= 0; i-- {
		var high, low Input
		for j := 0; j < i; j++ {
			high[j] = 1
			low[j] = 1
		}
		for j := i + 1; j < 14; j++ {
			high[j] = 9
			low[j] = 1
		}
		high[i] = 9
		low[i] = 2
		winner = scanRange(context.Background(), low.Int(), high.Int(), -1)
		if winner != nil {
			break
		}
	}
	dur := time.Since(start)
	if winner == nil {
		fmt.Println("❌ Part 2 has no winners!!! 😦")
	} else {
		fmt.Printf("✓ Part 2 found winner: %s in %s\n", winner, dur)
	}
}

func main() {
	if false {
		exploratory()
		os.Exit(0)
	}
	// If running the program more than once was valuable, some state could
	// perhaps be preserved from part1, but since my part 1 answer started with
	// 99, not much work would be saved in part 2.
	part1()
	part2()
	os.Exit(0)
}

// exploratory is where I tried some things out to see what might be inferred
// about changing individual digits.
func exploratory() {
	best := Input{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9}
	for i := 0; i < 14; i++ {
		input := best
		min := math.MaxInt
		for j := 9; j > 0; j-- {
			input[i] = j
			z, zvals := Compute_inputactual(input)
			if z == 0 {
				log.Printf("Got 0 z value from %v\nz vals %v\n", input, zvals)
			}
			if zvals[i+1] < min {
				log.Printf("Digit %d = %d got %d", i, j, zvals[i+1])
				best[i] = j
				min = zvals[i+1]
			}
		}
		log.Printf("Digit %d best %d partial %d", i, best[i], min)
	}
	zbest, _ := Compute_inputactual(best)
	fmt.Printf("Best: %s gets %d\n", best, zbest)
	tweak := best
	for i := 0; i < 14; i++ {
		min, _ := Compute_inputactual(tweak)
		minj := best[i]
		for j := 9; j > 0; j-- {
			tweak[i] = j
			z, zvals := Compute_inputactual(tweak)
			if z < min {
				log.Printf("Digit %d = %d with %s got z = %d, better than %d\n%v\n", i, j, tweak, z, min, zvals)
				min = z
				minj = j
			}
		}
		tweak[i] = minj
	}
	ztweak, _ := Compute_inputactual(tweak)
	fmt.Printf("Tweaked: %s gets %d\n", tweak, ztweak)
}
