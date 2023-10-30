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
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"
)

const shebang = "///usr/bin/true; exec /usr/bin/env go run \"$0\" \"`dirname $0`/runner.go\" \"$@\""
const dayCode = `// Copyright 2023 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

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
`

func main() {
	if len(os.Args) != 2 {
		log.Fatalf("Usage: %s path/to/dayX", os.Args[0])
	}
	outdir := os.Args[1]
	if err := os.MkdirAll(outdir, 0755); err != nil {
		log.Fatalf("Could not create %s: %v", outdir, err)
	}
	dayname := filepath.Base(outdir)
	dayvar := fmt.Sprintf("const dayName = %q", dayname)
	code := shebang + "\n" + dayCode + "\n" + dayvar + "\n"
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
