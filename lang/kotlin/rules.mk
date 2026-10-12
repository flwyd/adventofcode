# Copyright 2026 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

CLASSES = bin/classes
KOTLINC = kotlinc
KOTLINMAIN = $(DAY:day%=Day%)Kt
KOTLINRULES = $(lastword $(MAKEFILE_LIST))

.PHONY: clean clean-kotlin

# build-kotlin: $(CLASSES)/$(DAY)/$(KOTLINMAIN).class
build-kotlin: bin/$(DAY)kt

clean-kotlin:
	-rm -r bin/$(KOTLINMAIN).jar bin/$(DAY)kt

$(CLASSES)/$(DAY)/$(KOTLINMAIN).class: $(DAY).kt $(dir $(KOTLINRULES))runner.kt
	@mkdir -p $(CLASSES)
	$(KOTLINC) -d $(CLASSES) $^

bin/$(KOTLINMAIN).jar: $(DAY).kt $(dir $(KOTLINRULES))runner.kt
	@mkdir -p bin
	$(KOTLINC) -d $@ $^

bin/$(DAY)kt: bin/$(KOTLINMAIN).jar
	echo "#!/bin/sh" >| $@
	echo 'kotlin -cp `dirname $$0`/$(KOTLINMAIN).jar $(DAY).$(KOTLINMAIN) "$$@"' >> $@
	chmod a+x $@
