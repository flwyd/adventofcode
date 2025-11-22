#!/usr/bin/env ruby
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generates a skeletal Advent of Code solution in Ruby.

require 'pathname'
YEAR = 2025
INPUT_BASE = Pathname.new(__FILE__).parent + 'input'
if ARGV.empty?
  STDERR.puts "Usage: #{$PROGRAM_NAME} day1"
  exit 1
end
dayname = ARGV.shift
puts "Generating files in #{dayname}"
daynum = dayname.gsub(/\D+/, '')
dir = Pathname.new dayname
dir.mkdir unless dir.exist?
inputdir = INPUT_BASE + daynum
inputdir.mkdir unless inputdir.exist?

rubyfile = dir + "#{dayname}.rb"
unless rubyfile.exist?
  rubyfile.write <<~ENDCODE
    #!/usr/bin/env ruby
    # Copyright 2025 Trevor Stone
    #
    # Use of this source code is governed by an MIT-style
    # license that can be found in the LICENSE file or at
    # https://opensource.org/licenses/MIT.

    ##
    # Advent of Code #{YEAR} day #{daynum}
    # Read the puzzle at @see https://adventofcode.com/#{YEAR}/day/#{daynum}
    class Day#{daynum}
      def part1 lines
        'TODO'
      end

      def part2 lines
        'TODO'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require_relative '../runner.rb'
      exit Runner.new.run_day(Day#{daynum}.new, ARGV)
    end
  ENDCODE
  rubyfile.chmod 0755
end

%w(input.actual.txt input.actual.expected).map {|f| dir + f}.each do |f|
  File.symlink Pathname.new('..') + inputdir + f.basename, f unless f.exist? or f.symlink?
end
%w(input.example.txt input.actual.txt).map {|f| dir + f}.each do |f|
  f.write '' unless f.exist?
end
%w(input.example.exmaple input.actual.exmaple).map {|f| dir + f}.each do |f|
  f.write "part1: \npart2: \n" unless f.exist?
end
