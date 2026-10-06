#!/usr/bin/env -S perl -w
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generates an Advent of Code solution template in Perl.

use strict;
use feature qw(say);
use Cwd qw(cwd);
use File::Basename;
use File::Spec;

die "Usage: $0 day1" unless @ARGV;
my $daydir = shift;
if (!-d $daydir) {
  mkdir $daydir or die "Cannot create $daydir: $!";
};
my $day = basename($daydir);
my $year = basename(dirname(File::Spec->rel2abs($daydir)));
my $daynum;
($daynum = $day) =~ s/\D+//;
my @now = localtime;
my $copyyear = $now[5] + 1900;
my $langdir = File::Spec->abs2rel(dirname(__FILE__), File::Spec->rel2abs($daydir));
say "Generating files in $daydir";
my $perlfile = "$daydir/$day.pl";
if (!-e $perlfile) {
  open my $fh, '>', $perlfile or die "Cannot open $perlfile: $!";
  print $fh <<~EOT
  #!/usr/bin/env -S perl -w
  # Copyright $copyyear Trevor Stone
  #
  # Use of this source code is governed by an MIT-style
  # license that can be found in the LICENSE file or at
  # https://opensource.org/licenses/MIT.

  # Advent of Code $year day $daynum
  # Read the puzzle at https://adventofcode.com/$year/day/$daynum

  use strict;

  sub part1 {
    return 'TODO';
  }

  sub part2 {
    return 'TODO';
  }

  unless (caller) {
    use FindBin qw(\$Bin);
    require "\$Bin/$langdir/runner.pl";
  }
  EOT
  ; close($fh);
  chmod 0755, $perlfile;
}
my $inputdir = "$daydir/../input/$daynum";
mkdir $inputdir or die "Can't make $inputdir: $!" unless -d $inputdir;
foreach my $f (qw(input.actual.txt input.actual.expected)) {
  &touch("$inputdir/$f") unless -e "$inputdir/$f";
  unless (-e "$daydir/$f") {
    &touch("$inputdir/$f");
    symlink "../$inputdir/$f", "$daydir/$f";
  }
}
foreach my $f (qw(input.actual.expected input.example.expected)) {
  if (!-e "$daydir/$f" || -z "$daydir/$f") {
    open my $fh, ">", "$daydir/$f" or die "Cannot open $daydir/$f: $!";
    print $fh "part1: \npart2: \n";
    close $fh;
  }
}
&touch("$daydir/input.example.txt");

sub touch {
  my $file = shift;
  open TMPFILE, ">", $file and close TMPFILE
    or die "Could not create $file: $!" unless (-e $file);
}
