# Copyright 2023 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

1i local day4 = import 'day4.jsonnet';
1i day4 {
1i cards: [
s/^Card *\([0-9]\+\): *\(.*[0-9]\) *| *\(.*\)$/self.card(\1, [\2], [\3]),/
s/\([0-9]\) \+/\1, /g
$a ]
$a }.result.asPlainText
