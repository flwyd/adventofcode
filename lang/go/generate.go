// Copyright 2023 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// generate creates a skeletal go program to solve a day's Advent of Code
// problem, using runner.go to read input and log results.
package main

import (
	"errors"
	"log"
	"os"
	"path"
	"path/filepath"
	"runtime"
	"strings"
)

const shebang = "//usr/bin/true; exec /usr/bin/env go run \"$0\" \"`dirname $0`/runner.go\" \"$@\""

// TODO use template/text
const dayCode = `// Copyright YEAR Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code YEAR day DAYNUM https://adventofcode.com/YEAR/day/DAYNUM
package main

func part1(lines []string) string {
	return "TODO"
}

func part2(lines []string) string {
	return "TODO"
}

func main() {
	runMain(part1, part2)
}

const dayName = "dayDAYNUM"
`

func main() {
	if len(os.Args) != 2 {
		log.Fatalf("Usage: %s path/to/dayX", os.Args[0])
	}
	outdir := os.Args[1]
	if err := os.MkdirAll(outdir, 0755); err != nil {
		log.Fatalf("Could not create %s: %v", outdir, err)
	}
	var year string
	if p, err := filepath.Abs(path.Dir(outdir)); err != nil {
		log.Fatalf("Could not determine year from directory %s: %v", outdir, err)
	} else {
		year = path.Base(p)
	}
	dayname := filepath.Base(outdir)
	daynum := strings.TrimPrefix(dayname, "day")
	code := shebang + "\n" +
		strings.ReplaceAll(strings.ReplaceAll(dayCode, "DAYNUM", daynum), "YEAR", year)
	gofile := filepath.Join(outdir, dayname+".go")
	if fileExists(gofile) {
		log.Fatalf("%s already exists, exiting", gofile)
	}
	if err := os.WriteFile(gofile, []byte(code), 0755); err != nil {
		log.Fatalf("Error writing to %s: %v", gofile, err)
	}
	// create a symlink to runner.go, which is adjacent to generate.go
	runnerlink := filepath.Join(outdir, "runner.go")
	if !fileExists(runnerlink) {
		_, prog, _, ok := runtime.Caller(0)
		if !ok {
			log.Fatalf("Could not determine executable path, make sure to symlink runner.go")
		}
		runner := filepath.Join(filepath.Dir(prog), "runner.go")
		abs, err := filepath.Abs(outdir)
		if err != nil {
			log.Fatalf("Can't determine absolute path of %s: %v", outdir, err)
		}
		rel, err := filepath.Rel(abs, runner)
		if err != nil {
			log.Fatalf("Can't determine relative path of %s from %s: %v", runner, abs, err)
		}
		if err = os.Symlink(rel, runnerlink); err != nil {
			log.Fatalf("Error creating symlink to %s as %s: %v", rel, runnerlink, err)
		}
	}
	// doesn't create input.example.txt, input.example.expected, etc. because the
	// year's main generator has typically already made them
}

func fileExists(fname string) bool {
	_, err := os.Stat(fname)
	if errors.Is(err, os.ErrNotExist) {
		return false
	}
	if err != nil {
		log.Printf("Error checking %s: %v", fname, err)
	}
	return true
}
