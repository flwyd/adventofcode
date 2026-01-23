#!/usr/bin/env ruby
# Copyright 2025 Trevor Stone
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

require 'logger'
LOG = Logger.new(STDERR)

##
# Advent of Code 2025 day 12
# Read the puzzle at @see https://adventofcode.com/2025/day/12
#
# Input is 6 3x3 grid patterns (numbered 0 to 5) with # marking occupied spaces
# and . marking open ones.  Then comes a list of grid sizes and shape counts,
# e.g.  12x5: 1 0 1 0 2 2 meaning "try to fit 1 each of shape #0 and shape #2
# and 2 each of shape #4 and #5."  The atomic shape grids can be flipped and
# rotated and overlap open spaces.  The answer is the number of input lines
# where the given shape counts can all fit in a grid of the given size.
#
# Note that the general problem is NP-complete, and the shapes in the actual
# input form several perfect packings of various sizes, see
# https://www.reddit.com/r/adventofcode/comments/1q168p8/2025_day_12_part_1_perfect_packing_revisited/
class Day12
  def part1 lines
    atoms, goals = parse_input lines
    0.upto(goals.size-1).count do |goali|
      goal = goals[goali]
      # LOG.info "#{goali+1}: solving #{goal}"
      grid = trivial_solve goal, atoms # comment out for nicer packing
      # grid = simple_solve goal, atoms
      grid = packed_solve goal, atoms unless grid
      # LOG.info "Solved with\n#{grid}" if grid
      grid != nil
    end
  end

  def part2 lines
    'Merry Christmas!'
  end

  private
  def parse_input lines
    slices = lines.slice_after(&:empty?).to_a
    atoms = slices[...-1].map {|s| s.reject &:empty?}.map do |slice|
      num = slice.first.sub('#', '').to_i
      pts = (0..2).to_a.product((0..2).to_a).map {|x,y| Point.new(x, y)}.
        filter {|p| slice[1+p.y][p.x] == '#'}
      Atom.new num, pts.to_set
    end
    goals = slices.last.map do |line|
      line =~ /(\d+)x(\d+): (.*)/
      width, height = [$1, $2].map(&:to_i)
      targets = Hash.new(0)
      $3.split(' ').map(&:to_i).each_with_index {|x,i| targets[i] = x if x > 0}
      Goal.new width, height, targets.freeze
    end
    [atoms, goals]
  end

  def trivial_solve goal, atoms
    # Actual input (but not example) is all trivial
    return nil if goal.sizes.values.sum > (goal.width / 3) * (goal.height / 3)
    order = goal.sizes.flat_map {|k, v| [k] * v}.shuffle.map {|i| atoms[i]}
    x = y = 0
    points = Hash.new
    order.each do |a|
      a.points.each {|p| points[p.offset x, y] = a.id}
      x += 3
      if x + 2 >= goal.width then
        x = 0
        y += 3
      end
    end
    Grid.new goal.width, goal.height, points
  end

  def simple_solve goal, atoms
    needed = goal.sizes.map {|k,v| atoms[k].points.size * v}.sum
    if needed > goal.width * goal.height then
      return nil
    end
    g = Grid.new goal.width, goal.height
    avail = Array.new
    goal.sizes.each {|k,v| v.times {avail.push atoms[k]}}
    avail.shuffle!
    x = y = 0
    until avail.empty? do
      a = avail.pop
      g = g.merge_with a, x, y
      x += 3
      if x + 2 >= goal.width then
        x = 0
        y += 3
        break if y + 2 >= g.height
      end
    end
    if avail.empty? then g else nil end
  end

  def packed_solve goal, atoms
    # XXX: Since worth_trying? requires placements to be next to the edge or
    # the frontier of existing placements, it's possible in general to need
    # checking multiple permutations.  The tricky case in the example input
    # has 420 unique permutations of placement order; it's not worth checking
    # all of them.
    expanded = goal.sizes.flat_map {|k, v| [k] * v}.shuffle
    empty = Grid.new goal.width, goal.height
    order = expanded.map {|i| atoms[i]}
    packed_recurse empty, order
  end

  def packed_recurse grid, atoms, badstates=Set.new
    return grid if atoms.empty?
    avail = (grid.width * grid.height - grid.point_count)
    return nil if atoms.sum {|a| a.points.size} > avail
    state = [atoms.last.id, grid.points.keys.to_set]
    if badstates.include? state
      return nil
    end
    a = atoms.pop
    grid.open.sort.each do |point|
      if grid.worth_trying? point, a then
        a.family.each do |f|
          g = grid.merge_with f, point.x, point.y
          if g != nil then
            g = packed_recurse g, atoms, badstates
            return g if g != nil
          end
        end
      end
    end
    atoms.push a
    badstates.add state
    nil
  end
end

Point = Struct.new('Point', :x, :y) do |clazz|
  def to_s = "#{self.x},#{self.y}"

  def <=> o
    x != o.x ? x - o.x : y - o.y
  end

  def offset dx, dy
    Point.new x+dx, y+dy
  end

  def neighbors
    Point.neighborhood[self] ||= [
      offset(-1, -1), offset(0, -1), offset(+1, -1),
      offset(-1,  0), self,          offset(+1,  0),
      offset(-1, +1), offset(0, +1), offset(+1, +1),
    ]
  end

  private
  def self.neighborhood = @neighborhood ||= Hash.new
end

Atom = Struct.new('Atom', :id, :points) do |clazz|
  def to_s
    lines = (0..2).map do |row|
      (0..2).map do |col|
        points.include?(Point.new(col, row)) ? '#' : '.'
      end.join('')
    end
    "##{id}:\n#{lines.join("\n")}"
  end

  def family
    f = (@family ||= Set.new)
    if f.empty? then
      a = self
      4.times do
        # rotation, then horizontal flip, then vertical flip
        f << a
        f << Atom.new(id, a.points.map {|p| Point.new 2-p.x, p.y}.to_set)
        f << Atom.new(id, a.points.map {|p| Point.new p.x, 2-p.y}.to_set)
        a = Atom.new id, a.points.map {|p| Point.new 2-p.y, p.x}.to_set
      end
    end
    f
  end
end

class Grid
  attr :width, :height, :point_count, :points, :open

  def initialize w, h, pts=Hash.new, atom=nil, base=nil
    @width = w
    @height = h
    if base then
      ps = base.points.dup
      pts.each do |k,v|
        raise "Collision: adding #{pts} to #{self}" if ps.has_key? k
        ps[k] = v
      end
      @points = ps.freeze
      @point_count = base.point_count + pts.size
      op = base.open.dup
    else
      ps = pts.dup
      (-1..w).each do |x|
        ps[Point.new(x, -2)] = ':'
        ps[Point.new(x, -1)] = ':'
        ps[Point.new(x, height)] = ':'
        ps[Point.new(x, height+1)] = ':'
      end
      (-1..h).each do |y|
        ps[Point.new(-2, y)] = ':'
        ps[Point.new(-1, y)] = ':'
        ps[Point.new(width, y)] = ':'
        ps[Point.new(width+1, y)] = ':'
      end
      @points = ps.freeze
      @point_count = pts.size
      op = (0..w-2).flat_map {|x| (0..h-2).map {|y| Point.new x, y}}.to_set
    end
    unless pts.empty? then
      keys = pts.keys
      minx, maxx = keys.minmax {|p| p.x}
      miny, maxy = keys.minmax {|p| p.y}
      (minx.x-2..maxx.x+2).each do |x|
        (miny.y-2..maxy.y+2).each do |y|
          p = Point.new x, y
          op.delete(p) if op.include?(p) && !has_room?(p, 7)
        end
      end
    end
    @open = op.freeze
  end

  def merge_with atom, offx, offy
    pts = Hash.new
    atom.points.each do |p|
      o = p.offset offx, offy
      return nil if points.has_key? o
      pts[o] = atom.id
    end
    Grid.new width, height, pts, atom, self
  end

  def has_room? p, needed
    p.x >= 0 && p.y >= 0 && p.x < width-2 && p.y < height-2 &&
      needed <= (0..2).sum {|x| (0..2).count {|y| not points.has_key? p.offset(x, y)}}
  end

  def worth_trying? point, atom
    return false if point.x < 0 || point.y < 0 || point.x > width-3 || point.y > height-3
    full = point.neighbors.filter {|n| points.has_key? n}.size
    full > 2 && full < 9
  end

  def open_size = width * height - point_count

  def eql?(o)
    o.class == self.class && o.width == width &&
      o.height == height && o.points == points
  end
  alias == eql?

  def hash = [self.class, width, height, points].hash

  def to_s
    (0..height-1).map do |y|
      (0..width-1).map do |x|
        points[Point.new(x, y)] || '.'
      end.join('')
    end.join("\n")
  end
end

Goal = Struct.new('Goal', :width, :height, :sizes) do |clazz|
  def to_s
    "#{self.width}x#{self.height} #{(0..5).map {|i| self.sizes[i]}.join(" ")}"
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative '../runner.rb'
  exit Runner.new.run_day(Day12.new, ARGV)
end
