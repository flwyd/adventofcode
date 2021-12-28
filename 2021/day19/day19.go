/* Copyright 2021 Google LLC

Use of this source code is governed by an MIT-style
license that can be found in the LICENSE file or at
https://opensource.org/licenses/MIT.
*/
// https://adventofcode.com/2021/day/19 implementation in Go because day19.raku
// was really slow and nondeterministically got the wrong answer.  The Go
// implementation also nondeterministically got the wrong answer because
// iteration order through a map isn't consistent and I incorrectly believed
// that rotation was a commutative operation.
package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
)

type Direction int

const (
	Deosil      Direction = 1  // clockwise
	Widdershins Direction = -1 // not actually used, but makes math more robust
)

type Rotation struct{ x, y, z int }

var (
	face1    = Rotation{}
	face2    = Rotation{y: 1}
	face3    = Rotation{y: 2}
	face4    = Rotation{y: 3}
	face5    = Rotation{z: 1}
	face6    = Rotation{z: 3}
	allFaces = []Rotation{face1, face2, face3, face4, face5, face6}
	xTurns   = []Rotation{Rotation{}, Rotation{x: 1}, Rotation{x: 2}, Rotation{x: 3}}
)

func (r Rotation) String() string {
	return fmt.Sprintf("Rotation{x:%d,y:%d,z:%d}", r.x, r.y, r.z)
}

func (r Rotation) union(o Rotation) Rotation {
	return Rotation{r.x + o.x, r.y + o.y, r.z + o.z}
}

type Point struct{ x, y, z int }

func (p Point) rotate(axis string, dir Direction) Point {
	switch axis {
	case "x":
		return Point{x: p.x, y: p.z * int(dir), z: -p.y * int(dir)}
	case "y":
		return Point{x: -p.z * int(dir), y: p.y, z: p.x * int(dir)}
	case "z":
		return Point{x: p.y * int(dir), y: -p.x * int(dir), z: p.z}
	default:
		log.Fatalf("Unknown axis %s", axis)
		return p
	}
}

func (p Point) rotateMultiple(axes Rotation) Point {
	q := p
	if axes.x != 0 {
		dir := Deosil
		if axes.x < 0 {
			dir = Widdershins
		}
		for i := 0; i < int(dir)*axes.x; i++ {
			q = q.rotate("x", dir)
		}
	}
	if axes.y != 0 {
		dir := Deosil
		if axes.y < 0 {
			dir = Widdershins
		}
		for i := 0; i < int(dir)*axes.y; i++ {
			q = q.rotate("y", dir)
		}
	}
	if axes.z != 0 {
		dir := Deosil
		if axes.z < 0 {
			dir = Widdershins
		}
		for i := 0; i < int(dir)*axes.z; i++ {
			q = q.rotate("z", dir)
		}
	}
	return q
}

func (p Point) plus(o Point) Point {
	return Point{x: p.x + o.x, y: p.y + o.y, z: p.z + o.z}
}

func (p Point) minus(o Point) Point {
	return Point{x: p.x - o.x, y: p.y - o.y, z: p.z - o.z}
}

func (p Point) String() string {
	return fmt.Sprintf("%d,%d,%d", p.x, p.y, p.z)
}

type Pointset struct {
	points   map[Point]bool
	origin   Point
	rotation Rotation
}

func (s *Pointset) rotate(axes Rotation) *Pointset {
	res := make(map[Point]bool)
	for p := range s.points {
		res[p.rotateMultiple(axes)] = true
	}
	return &Pointset{points: res, origin: s.origin.rotateMultiple(axes), rotation: s.rotation.union(axes)}
}

func (s *Pointset) allOrientations() []*Pointset {
	res := make([]*Pointset, 0, 24)
	for _, f := range allFaces {
		for _, x := range xTurns {
			res = append(res, s.rotate(f.union(x)))
		}
	}
	return res
}

func (s *Pointset) offset(p Point) *Pointset {
	res := make(map[Point]bool)
	for q := range s.points {
		res[q.plus(p)] = true
	}
	return &Pointset{points: res, origin: s.origin.plus(p), rotation: s.rotation}
}

func (s *Pointset) overlap(o *Pointset) *Pointset {
	for p := range s.points {
		for q := range o.points {
			t := o.offset(p.minus(q))
			matches := 0
			for r := range t.points {
				if s.points[r] {
					matches++
				}
			}
			if matches >= 12 {
				return t
			}
		}
	}
	return nil
}

func (s *Pointset) String() string {
	points := make([]string, 0, len(s.points))
	for p := range s.points {
		points = append(points, p.String())
	}
	return fmt.Sprintf("Pointset( %s )", strings.Join(points, "  "))
}

type Device struct {
	name         string
	pointset     *Pointset
	orientations []*Pointset
}

func (d *Device) String() string {
	points := make([]string, 0, len(d.pointset.points))
	for p := range d.pointset.points {
		points = append(points, p.String())
	}
	return fmt.Sprintf("%s\n%s", d.name, strings.Join(points, "\n"))
}

func align(devices []*Device) map[int]*Pointset {
	found := make(map[int]*Pointset)
	found[0] = devices[0].pointset
	checked := make(map[int]map[int]bool)
	remaining := len(devices) - 1
	for remaining > 0 {
		thisloop := 0
	eachdevice:
		for i := range devices {
			if checked[i] == nil {
				checked[i] = make(map[int]bool)
			}
			if found[i] != nil {
				continue
			}
			for j := range devices {
				if i == j || found[j] == nil || checked[i][j] {
					continue
				}
				checked[i][j] = true
				source := found[j]
				for _, orient := range devices[i].orientations {
					o := source.overlap(orient)
					if o == nil {
						continue
					}
					found[i] = o
					remaining--
					thisloop++
					continue eachdevice
				}
			}
		}
		if thisloop == 0 {
			log.Fatalf("Couldn't make any progress after %d matches\n%v", len(found), found)
		}
	}
	return found
}

// part1 counts the number of distinct points after aligning all scanner devices.
func part1(devices []*Device) int {
	found := align(devices)
	all := make(map[Point]int)
	for _, s := range found {
		for p := range s.points {
			all[p]++
		}
	}
	return len(all)
}

// part1 counts the maximum Manhattan distance between two scanner devices.
func part2(devices []*Device) int {
	found := align(devices)
	max := 0
	for _, ps1 := range found {
		for _, ps2 := range found {
			p := ps1.origin.minus(ps2.origin)
			max = maxInt(max, absInt(p.x)+absInt(p.y)+absInt(p.z))
		}
	}
	return max
}

func absInt(a int) int {
	if a >= 0 {
		return a
	}
	return -1 * a
}
func maxInt(a, b int) int {
	if b > a {
		return b
	}
	return a
}

func runFile(fname string) {
	f, err := os.Open(fname)
	if err != nil {
		log.Fatalf("Error opening %s: %v", fname, err)
	}
	defer f.Close()
	devices := make([]*Device, 0)
	var dev *Device
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "scanner") {
			dev = &Device{name: line, pointset: &Pointset{points: make(map[Point]bool)}}
			devices = append(devices, dev)
		} else if strings.ContainsRune(line, ',') {
			var x, y, z int
			if _, err := fmt.Sscanf(line, "%d,%d,%d", &x, &y, &z); err != nil {
				log.Fatalf("Could not parse %s", line)
				continue
			}
			dev.pointset.points[Point{x: x, y: y, z: z}] = true
		}
	}
	for _, d := range devices {
		d.orientations = d.pointset.allOrientations()
	}
	fmt.Printf("Running Part 1 on %s\n", fname)
	start := time.Now()
	res1 := part1(devices)
	dur := time.Since(start)
	fmt.Printf("Part 1 got %d\n", res1)
	fmt.Printf("Part 1 took %s\n", dur)
	fmt.Printf("Running Part 2 on %s\n", fname)
	start = time.Now()
	res2 := part2(devices)
	dur = time.Since(start)
	fmt.Printf("Part 2 got %d\n", res2)
	fmt.Printf("Part 2 took %s\n", dur)
}

func main() {
	for _, fname := range os.Args[1:] {
		fmt.Printf("Running day19 on %s\n", fname)
		start := time.Now()
		runFile(fname)
		dur := time.Since(start)
		fmt.Printf("%s took %s\n", fname, dur)
	}
}
