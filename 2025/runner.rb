# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

##
# Advent of Code runner for Ruby.  Provide an object with part1 and part2
# methods which take an array of strings (one per line in an input file).
# Command line args are a list of input files and optionally +-v+ or +--verbose+
# to enable information printed to stderr.
class Runner
  def run_day(day, args)
    verbose, files = args.partition {|s| %w(-v --verbose).include? s}
    @verbose = !verbose.empty?
    files = ['-'] if files.empty?
    files.each {|f| run_file day, f}.count.clamp(0, 1)
  end

  def run_file(day, fname)
    lines = if fname == '-'
              STDIN.readlines(chomp: true)
            else
              IO.readlines(fname, chomp: true)
            end.freeze
    log "Running #{day.class} on #{fname} (#{lines.size} lines)"
    expected = Hash.new ""
    expfile = fname.sub('.txt', '.expected')
    if fname != '-' and File.exist? expfile
      IO.readlines(expfile, chomp: true).each do |line|
        part, exp = line.split /:\s*/
        expected[part.to_sym] = (exp||'').gsub('\n', "\n") # handle ASCII art letters
      end
    end
    results = [:part1, :part2].map do |p|
      run_part day, p, fname, lines, expected[p]
    end
    results.none? {|r| r == :fail}
  end

  def run_part(day, part, fname, lines, expected)
    before = Time.now
    got = day.send part, lines
    after = Time.now
    puts "#{part}: #{got}"
    STDOUT.flush
    outcome = case got.to_s
        when expected
          :success
        when 'TODO'
          :todo
        else
          expected.empty? ? :unknown : :fail
        end
    r = log Result.new(outcome, got, expected || '')
    log "#{part} took #{format_duration(after - before)} on #{fname}"
    STDERR.flush
    log '=' * 40
    STDERR.flush
    r
  end

  def format_duration(secs)
    if secs < 0.001
      format("%dμs", secs * 1_000_000)
    elsif secs < 1
      format("%dms", secs * 1000)
    elsif secs < 60
      format("%.3fs", secs)
    elsif secs < 3600
      format('%d:%02d', secs / 60, secs % 60)
    else
      format('%d:%02d:%02d', secs / 3600, secs % 3600 / 60, secs % 60)
    end
  end

  def log(message)
    STDERR.puts message.to_s if @verbose
    message
  end

  private
  Result = Struct.new('Result', :outcome, :got, :want) do |clazz|
    @@symbols = {success: '✅', fail: '❌', todo: '❗', unknown: '❓'}

    def to_s
      msg = case outcome
            when :success, :unknown
              "got #{got}"
            when :fail
              "got #{got}, want #{want}"
            when :todo
              want.empty? ? "implement it" : "implement it, want #{want}"
            end
      "#{@@symbols[outcome]} #{outcome.to_s.upcase} #{msg}"
    end
  end
end
