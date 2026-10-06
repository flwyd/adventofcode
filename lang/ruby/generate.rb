#!/usr/bin/env ruby
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Generates a skeletal Advent of Code solution in Ruby.

require 'date'
require 'pathname'
if ARGV.empty?
  STDERR.puts "Usage: #{$PROGRAM_NAME} day1"
  exit 1
end
LANG_DIR = Pathname.new(__FILE__).expand_path.parent
puts (LANG_DIR + 'runner.rb').to_s
dayname = ARGV.shift
puts "Generating files in #{dayname}"
dir = Pathname.new dayname
dir.mkdir unless dir.exist?
daynum = dir.basename.to_s.gsub(/\D+/, '')
year = dir.parent.expand_path.basename
inputdir = dir.parent + "input" + daynum
inputdir.mkpath unless inputdir.exist?
rubyfile = dir + "#{dir.basename}.rb"
runnerpath = LANG_DIR.relative_path_from(dir.expand_path) + 'runner.rb'
unless rubyfile.exist?
  rubyfile.write <<~ENDCODE
    #!/usr/bin/env ruby
    # Copyright #{Date.today.year} Trevor Stone
    #
    # Use of this source code is governed by an MIT-style
    # license that can be found in the LICENSE file or at
    # https://opensource.org/licenses/MIT.

    ##
    # Advent of Code #{year} day #{daynum}
    # Read the puzzle at @see https://adventofcode.com/#{year}/day/#{daynum}
    class Day#{daynum}
      def part1 lines
        'TODO'
      end

      def part2 lines
        'TODO'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require_relative '#{runnerpath}'
      exit Runner.new.run_day(Day#{daynum}.new, ARGV)
    end
  ENDCODE
  rubyfile.chmod 0755
end

%w(input.actual.txt input.actual.expected).map {|f| dir + f}.each do |f|
  target = inputdir.relative_path_from(dir)
  File.symlink target + f.basename, f unless f.exist? or f.symlink?
end
%w(input.example.txt input.actual.txt).map {|f| dir + f}.each do |f|
  f.write '' unless f.exist?
end
%w(input.example.expected input.actual.expected).map {|f| dir + f}.each do |f|
  f.write "part1: \npart2: \n" unless f.exist?
end
