# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Snippet to build an Advent of Code day solution in Rust.
# The including makefile should set `DAY = dayX` and have `build-rust` in the
# `build` rule and `clean-rust` in the `clean` rule.

RUSTC = rustc --edition=2024
RUSTBIN = bin/$(DAY)rs
RUSTRULES = $(lastword $(MAKEFILE_LIST))

.PHONY: clean clean-rust

build-rust: $(RUSTBIN)

clean-rust:
	-rm $(RUSTBIN)

$(RUSTBIN): $(DAY).rs runner.rs
	mkdir -p bin
	$(RUSTC) -o $(RUSTBIN) $(DAY).rs

runner.rs:
	ln -s $(dir $(RUSTRULES))runner.rs runner.rs
