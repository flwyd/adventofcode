# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# https://adventofcode.com/2020/day/13

KOTLIN = kotlin
KOTLINC = kotlinc
CLASSES = classes
PACKAGE = day13
MAIN_CLASS = Day13Kt

compile: $(CLASSES)/$(PACKAGE)/$(MAIN_CLASS).class

$(CLASSES)/$(PACKAGE)/$(MAIN_CLASS).class: $(PACKAGE).kt
	@mkdir -p $(CLASSES)
	$(KOTLINC) -d $(CLASSES) $(PACKAGE).kt

output.%.txt: input.%.txt compile
	$(KOTLIN) -cp $(CLASSES) $(PACKAGE).$(MAIN_CLASS) < $< | tee $@

out: output.example.txt output.actual.txt

clean:
	rm -r $(CLASSES)
