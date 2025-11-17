module "runner";
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code runner harness for the jq language.

def maybelog(message):
  (if $ARGS.named.verbose // false then message else empty end |
    stderr | empty), .;

def expectedvalues:
  rtrimstr("\n") | split("\n") | map(split(": *"; "")) |
    map({key: .[0], value: .[1]}) | from_entries;

def before($day): maybelog(
  "Running day \($day) on \(input_filename) (\(input_line_number) lines)\n");

def result:
  ((($ARGS.named.expected // "") | expectedvalues)[.key] // "") as $expected |
  {part: .key, got: (.value | tostring), want: $expected,
    status: (if $expected == (.value | tostring) then "success"
      else if .value == "TODO" then "todo"
      else if $expected == "" then "unknown"
      else "fail"
      end end end)};

def signs: {success: "✅", fail: "❌", unknown: "❓", todo: "❗"};

def resultmessage:
  (if .status == "success" or .status == "unknown" then "got \(.got)"
    else if .status == "fail" then "got \(.got), wanted \(.want)"
    else if .want == "" then "implement it"
    else "implement it, want \(.want)"
    end end end
  ) as $message | "\(signs[.status]) \(.status | ascii_upcase) \($message)\n";

def outcome: to_entries | map(result | maybelog(resultmessage));

def finish:
  outcome | if any(.status == "fail") then "" | halt_error(1) else halt end;

def run($daynum; part1; part2):
  before($daynum) | rtrimstr("\n") | split("\n") |
  {part1: part1, part2: part2} |
  "part1: \(.part1)\npart2: \(.part2)",
  finish;
