// Copyright 2023 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// runner.go provides runMain and other support functions to read input files,
// run an Advent of Code solution, and log the results.
// Symlink to this file from the directory with the solution and run with
// % go run dayX/*.go -v path/to/input.*.txt
// which enables running everything in a single main package without modules.

package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
	"time"
)

type Part func(lines []string) string

var (
	verbose = false
)

func runMain(part1, part2 Part) {
	log.SetFlags(log.Ltime)
	flag.BoolVar(&verbose, "verbose", false, "log time and status")
	flag.BoolVar(&verbose, "v", false, "log time and status")
	flag.Parse()
	files := flag.Args()
	if len(files) == 0 {
		files = []string{"-"} // read stdin
	}
	success := true
	for _, fname := range files {
		success = runFile(fname, part1, part2) && success
	}
	if success {
		os.Exit(0)
	}
	os.Exit(1)
}

func runFile(fname string, part1, part2 Part) bool {
	lines, err := readLines(fname)
	if err != nil {
		log.Fatal(err)
	}
	expect := readExpected(fname)
	p1 := execution{part: part1, partName: "part1", fileName: fname, lines: lines, expected: expect[0]}
	p2 := execution{part: part2, partName: "part2", fileName: fname, lines: lines, expected: expect[1]}
	success := p1.run()
	success = p2.run() && success
	return success
}

func readLines(fname string) ([]string, error) {
	var f io.Reader
	if fname == "-" {
		f = os.Stdin
	} else {
		file, err := os.Open(fname)
		if err != nil {
			return nil, fmt.Errorf("error reading %s: %v", fname, err)
		}
		defer file.Close()
		f = file
	}
	lines := make([]string, 0)
	s := bufio.NewScanner(f)
	for s.Scan() {
		lines = append(lines, s.Text())
	}
	if err := s.Err(); err != nil {
		return nil, fmt.Errorf("error reading lines from %s: %v", fname, err)
	}
	return lines, nil
}

func readExpected(inputfname string) [2]string {
	res := [2]string{"", ""}
	if !strings.HasSuffix(inputfname, ".txt") {
		return res
	}
	efname := strings.TrimSuffix(inputfname, "txt") + "expected"
	f, err := os.Open(efname)
	if err != nil {
		return res
	}
	defer f.Close()
	s := bufio.NewScanner(f)
	for s.Scan() {
		line := s.Text()
		if strings.HasPrefix(line, "part1: ") {
			res[0] = strings.TrimPrefix(line, "part1: ")
		}
		if strings.HasPrefix(line, "part2: ") {
			res[1] = strings.TrimPrefix(line, "part2: ")
		}
	}
	for i, t := range res {
		res[i] = strings.ReplaceAll(t, "\\n", "\n")
	}
	return res
}

type execution struct {
	part     Part
	partName string
	fileName string
	lines    []string
	expected string
}

func (e execution) run() bool {
	if verbose {
		log.Printf("Running %s %s on %s (%d lines)", dayName, e.partName, e.fileName, len(e.lines))
	}
	start := time.Now()
	l := make([]string, len(e.lines))
	copy(l, e.lines)
	res := e.part(l)
	elapsed := time.Since(start)
	fmt.Printf("%s: %s\n", e.partName, res)
	if verbose {
		var msg string
		if res == e.expected {
			msg = fmt.Sprintf("✅ %s got %s", colored(colorSuccess, "SUCCESS"), res)
		} else if res == "TODO" {
			msg = fmt.Sprintf("❗ %s implement it", colored(colorTodo, "TODO"))
			if e.expected != "" {
				msg += fmt.Sprintf(", want %s", e.expected)
			}
		} else if e.expected == "" {
			msg = fmt.Sprintf("❓ %s got %s", colored(colorUnknown, "UNKNOWN"), res)
		} else {
			msg = fmt.Sprintf("❌ %s got %s, want %s", colored(colorFailure, "FAILURE"), res, e.expected)
		}
		log.Println(msg)
		log.Printf("%s took %s on %s", e.partName, elapsed, e.fileName)
	}
	return res == e.expected
}

const (
	colorSuccess = "30;102" // black on bright green
	colorFailure = "30;101" // black on bright red
	colorUnknown = "30;103" // black on bright yellow
	colorTodo    = "30;106" // black on bright cyan
)

func colored(color, s string) string {
	return fmt.Sprintf("\x1B[%sm%s\x1B[0m", color, s)
}
