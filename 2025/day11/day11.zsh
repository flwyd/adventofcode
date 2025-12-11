#!/bin/zsh
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Advent of Code 2025 day 11
# Read the puzzle at https://adventofcode.com/2025/day/11

source ${0:h:h}/runner.zsh
((VERBOSE=0))
if [[ $1 == "-v" ]]; then
  ((VERBOSE=1))
  shift
fi
DAY=day11

function solve {
  local inputfile=$1
  dotfile=$(mktemp -t "${DAY}_dot1")
  dotfileout=$(mktemp -t "${DAY}_dot2")
  dotfileout2=$(mktemp -t "${DAY}_dot3")
  dotfileout3=$(mktemp -t "${DAY}_dot4")
  # echo "DOT in $dotfile outfile $dotfileout $dotfileout2 $dotfileout3"
  echo 'digraph {' >> $dotfile
  awk -F': ' '{
    split($2, a, " ");
    for (x in a) { print $1 " -> " a[x] ";" }
  }' $inputfile | sort >> $dotfile
  echo '}' >> $dotfile
  gvpr -a "$dotfileout" '
  BEG_G {
    $tvroot = node($G, "you");
    $tvtype = TV_postfwd;
    aset(node($G, "out"), "count", 1);
  }
  N {
    edge_t e;
    long count = aget($, "count");
    for (e = fstout($); e != NULL; e = nxtout(e)) {
      count += aget(e.head, "count");
    }
    aset($, "count", count);
  }
  END_G {
    writeG($G, ARGV[0]);
    node_t you = node($G, "you");
    printf("part1: %d\n", aget(you, "count"));
  }
  ' $dotfile | while IFS='' read -r line ; do
    if [[ $line =~ 'part[12]:*' ]]; then
        typeset ${line/: /=}
    fi
  done
  gvpart2='
  BEG_G {
    $tvroot = node($G, "svr");
    $tvtype = TV_postfwd;
    string subj = sprintf("saw%s", ARGV[0]);
    node_t n = node($G, ARGV[0]);
    aset(n, subj, aget(n, "count"));
    if (hasAttr(n, "sawdac") && hasAttr(n, "sawfft")) {
      long bothdac = aget(n, "sawdac");
      long bothfft = aget(n, "sawfft");
      if (bothfft > bothdac) { aset(n, "sawboth", bothdac); }
      else { aset(n, "sawboth", bothfft); }
    }
  }
  N {
    edge_t e;
    for (e = fstout($); e != NULL; e = nxtout(e)) {
      if (hasAttr(e.head, subj) && aget(e.head, subj) > 0) {
        long cur = 0;
        if (hasAttr($, subj)) cur = aget($, subj);
        aset($, subj, aget(e.head, subj) + cur);
      }
    }
    for (e = fstout($); e != NULL; e = nxtout(e)) {
      if (hasAttr(e.head, "sawboth") && aget(e.head, "sawboth") > 0) {
        long bcur = 0;
        if (hasAttr($, "sawboth")) bcur = aget($, "sawboth");
        aset($, "sawboth", aget(e.head, "sawboth") + bcur);
      }
    }
  }
  END_G {
    writeG($G, ARGV[1]);
    node_t svr = node($G, "svr");
    if (hasAttr(svr, "sawboth")) {
      printf("part2: %d\n", aget(svr, "sawboth"));
    } else {
      print("part2: 0");
    }
  }
  '
  gvpr -a dac -a "$dotfileout2" $gvpart2 $dotfileout > /dev/null
  gvpr -a fft -a "$dotfileout3" $gvpart2 $dotfileout2 \
  | while IFS='' read -r line ; do
    if [[ $line =~ 'part[12]:*' ]]; then
        typeset ${line/: /=}
    fi
  done
  PART1=$part1
  PART2=$part2
}

runner_solve_files $@
exit $(($FAILURES > 0))
