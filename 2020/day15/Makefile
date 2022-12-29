# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# https://adventofcode.com/2020/day/15

KOTLIN = kotlin
KOTLINC = kotlinc
CLASSES = classes
PACKAGE = day15
MAIN_CLASS = Day15Kt

compile: $(CLASSES)/$(PACKAGE)/$(MAIN_CLASS).class

$(CLASSES)/$(PACKAGE)/$(MAIN_CLASS).class: $(PACKAGE).kt
	@mkdir -p $(CLASSES)
	$(KOTLINC) -d $(CLASSES) $(PACKAGE).kt

output.%.txt: input.%.txt compile
	$(KOTLIN) -cp $(CLASSES) $(PACKAGE).$(MAIN_CLASS) < $< | tee $@

out: output.example.txt output.example2.txt output.example3.txt output.example4.txt output.example5.txt output.example6.txt output.example7.txt output.actual.txt

clean:
	rm -r $(CLASSES)
