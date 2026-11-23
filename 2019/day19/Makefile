# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

DAY = day19

.PHONY: clean-rust-alt

build: build-rust build-rust-alt

clean: clean-rust clean-rust-alt

include ../../lang/rust/rules.mk

DAYALT = day19alt
ALTBIN = bin/$(DAYALT)rs
$(ALTBIN): day19alt.rs runner.rs
	mkdir -p bin
	$(RUSTC) -o $(ALTBIN) $(DAYALT).rs

build-rust-alt: $(ALTBIN)

clean-rust-alt:
	-rm $(ALTBIN)
