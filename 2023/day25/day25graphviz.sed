# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Transforms https://adventofcode.com/2023/day/25 input to DOT format.
# Send the result to `neato -Tsvg` to find the three obvious edges to cut.

1 {
x
/^$/i\
graph {
g
}
/:$/ {
$a\
}
d
}
/:/ {
s/^\(...\): \(...\)\(.*\)/\1 -- \2\n\1:\3/
P
D
}
