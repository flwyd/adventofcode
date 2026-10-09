//usr/bin/true; exec /usr/bin/env go run "$0" "$@"
//// Copyright 2023 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// generate creates a skeletal go program to solve a day's Advent of Code
// problem, using runner.go to read input and log results.
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const shebang = "//usr/bin/true; exec /usr/bin/env go run \"$0\" \"`dirname $0`/runner.go\" \"$@\""

// TODO use template/text
const dayCode = `// Copyright COPYDATE Trevor Stone
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

// Advent of Code YEAR day DAYNUM
// Read the puzzle at https://adventofcode.com/YEAR/day/DAYNUM
package main

type DayDAYNUM struct{}

func (_ DayDAYNUM) String() string { return "dayDAYNUM" }

func (_ DayDAYNUM) Part1(lines []string) string {
	return "TODO"
}

func (_ DayDAYNUM) Part2(lines []string) string {
	return "TODO"
}

func main() {
	runDay(DayDAYNUM{})
}

const dayName = "dayDAYNUM"
`

const expectedContent = "part1: \npart2: \n"

func main() {
	if len(os.Args) != 2 {
		log.Fatalf("Usage: %s path/to/dayX", os.Args[0])
	}
	outdir := os.Args[1]
	if err := os.MkdirAll(outdir, 0755); err != nil {
		log.Fatalf("Could not create %s: %v", outdir, err)
	}
	thisyear := fmt.Sprintf("%d", time.Now().Year())
	var year string
	if p, err := filepath.Abs(path.Dir(outdir)); err != nil {
		log.Fatalf("Could not determine year from directory %s: %v", outdir, err)
	} else {
		year = path.Base(p)
	}
	dayname := filepath.Base(outdir)
	daynum := strings.TrimPrefix(dayname, "day")
	rep := strings.NewReplacer("DAYNUM", daynum, "YEAR", year, "COPYDATE", thisyear)
	code := shebang + "\n" + rep.Replace(dayCode)
	gofile := filepath.Join(outdir, dayname+".go")
	if fileExists(gofile) {
		log.Fatalf("%s already exists, exiting", gofile)
	}
	log.Printf("Creating files in %s", outdir)
	writeFile(gofile, code, true)
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
	// create input files if needed
	writeIfMissing(filepath.Join(outdir, "input.example.expected"), expectedContent)
	writeIfMissing(filepath.Join(outdir, "input.example.txt"), "")
	for actual, content := range map[string]string{"input.actual.txt": "", "input.actual.expected": expectedContent} {
		outfile := filepath.Join(outdir, actual)
		if fileExists(outfile) {
			continue
		}
		inputdir := filepath.Join(filepath.Dir(outdir), "input", daynum)
		if !fileExists(inputdir) {
			if err := os.Mkdir(inputdir, 0755); err != nil {
				log.Fatalf("Error creating %s: %v", inputdir, err)
			}
		}
		fname := filepath.Join(inputdir, actual)
		writeIfMissing(fname, content)
		rel, err := filepath.Rel(outdir, fname)
		if err != nil {
			log.Fatalf("Error getting relative path for %s: %v", fname, err)
		}
		if err := os.Symlink(rel, path.Join(outdir, actual)); err != nil {
			log.Fatalf("Error symlinking %s to %s: %v", actual, rel, err)
		}
	}
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

func writeFile(fname, content string, executable bool) {
	mode := fs.FileMode(0644)
	if executable {
		mode |= 0100
	}
	if err := os.WriteFile(fname, []byte(content), mode); err != nil {
		log.Fatalf("Error writing %d bytes to %s: %v", len(content), fname, err)
	}
	log.Printf("Created %s", fname)
}

func writeIfMissing(fname, content string) {
	if !fileExists(fname) {
		writeFile(fname, content, false)
	}
}
