#!/usr/bin/env -S perl -w
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generates an Advent of Code solution template in Perl.

use strict;
use feature qw(say);

die "Usage: $0 day1" unless @ARGV;
my $daydir = shift;
my $day;
($day = $daydir) =~ s/\D+//;
my $year = 2025;
if (!-d $daydir) {
  mkdir $daydir or die "Cannot create $daydir: $!";
};
say "Generating files in $daydir";
my $perlfile = "$daydir/$daydir.pl";
if (!-e $perlfile) {
  open my $fh, '>', $perlfile;
  print $fh <<~EOT
  #!/usr/bin/env -S perl -w
  # Copyright 2025 Trevor Stone
  #
  # Use of this source code is governed by an MIT-style
  # license that can be found in the LICENSE file or at
  # https://opensource.org/licenses/MIT.

  # Advent of Code $year day $day
  # Read the puzzle at https://adventofcode.com/$year/day/$day

  use strict;

  sub part1 {
    return 'TODO';
  }

  sub part2 {
    return 'TODO';
  }

  unless (caller) {
    use FindBin qw(\$Bin);
    require "\$Bin/../runner.pl";
  }
  EOT
  ; close($fh);
  chmod 0755, $perlfile;
}
my $inputdir = "input/$day";
mkdir $inputdir or die "Can't make $inputdir: $!" unless -d "input/$day";
foreach my $f (qw(input.actual.txt input.actual.expected)) {
  &touch("$inputdir/$f") unless -e "$inputdir/$f";
  unless (-e "$daydir/$f") {
    my $time = time;
    &touch("$inputdir/$f");
    symlink "../$inputdir/$f", "$daydir/$f";
  }
}
foreach my $f (qw(input.actual.expected input.example.expected)) {
  if (!-e "$daydir/$f" || -z "$daydir/$f") {
    open my $fh, ">", "$daydir/$f";
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
