#!/usr/bin/env raku
# Copyright 2021 Google LLC
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generator script for a day's Advent of Code files.  Usage:
# ./generate day1

sub MAIN(Str:D $day-dir-name) {
  my $day-dir = $day-dir-name.IO;
  my $class-name = $day-dir.basename.tc;
  my $day-num = $class-name.match(/\d+$/).Str;
  my $script = $day-dir.add($day-dir.basename ~ '.raku');
  $day-dir.mkdir;
  for <input.example.txt input.actual.txt>.map({ $day-dir.add($_) }) {
    $_.spurt('') unless $_.f;
  }
  $script.spurt(qq:to/END/) unless $script.f;
    #!/usr/bin/env raku
    # Copyright 2021 Google LLC
    #
    # Use of this source code is governed by an MIT-style
    # license that can be found in the LICENSE file or at
    # https://opensource.org/licenses/MIT.
    #
    # https://adventofcode.com/2021/day/$day-num

    class $class-name \{
      has \$.input;

      method solve-part1(--> Cool:D) \{
        return "TODO";
      }

      method solve-part2(--> Cool:D) \{
        return "TODO";
      }
    }

    sub MAIN(*@input-files) \{
      for @input-files -> \$input-file \{
        if (my \$input = \$input-file.IO.slurp) \{
          say "Running $class-name part 1 on \$input-file";
          my \$start1 = now;
          my \$solver = {$class-name}.new(:input(\$input));
          say \$solver.solve-part1();
          "Part 1 took %.3fms\\n".printf((now - \$start1)*1000);
          say '';
          say "Running $class-name part 2 on \$input-file";
          my \$start2 = now;
          \$solver = {$class-name}.new(:input(\$input));
          say \$solver.solve-part2();
          "Part 2 took %.3fms\\n".printf((now - \$start2)*1000);
        } else \{
          say "EMPTY INPUT FILE: \$input-file";
        }
        say '=' x 40;
      }
    }
    END
  $script.chmod(0o755);
}
