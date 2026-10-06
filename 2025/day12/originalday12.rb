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
class Day12
  def part1 lines
    atoms, goals = self.parse_input lines
    # 0.upto(5).each do |i|
    #   LOG.info "Atom's family #{i} is #{atoms[i].family.size}"
    # end
    # goals.map do |g|
    #   total = g.sizes.map {|k,v| atoms[k].point_count * v}.sum
    #   size = g.width * g.height
    #   [size - total, format('%.3f', size.to_f / total), size, total, g.width, g.height]
    # end.sort.each {|x| LOG.info x.join(' ')}
    # LOG.info "atoms"
    # atoms.each {|a| LOG.info a.atoms, a.family.size; puts a.family.join("\n===\n")}
    # LOG.info "goals"
    # goals.map {|g| LOG.info g.to_s}
    # library = Set.new(atoms.map(&:family).map(&:to_a).flatten)
    # LOG.info "library size: #{library.size}"
    # cache = Cache.new
    # atoms.each {|a| cache.add a}
    0.upto(goals.size-1).count do |goali|
      goal = goals[goali]
      # LOG.info "Starting on ##{goali+1} #{goal}"
      solved = simple_solve goal, atoms
      if solved.nil? then
        solved = exhaustive_solve goal, atoms
      end
      unless solved.nil? then
        needed = goal.sizes.map {|k,v| atoms[k].point_count * v}.sum
        if solved.point_count != needed then
          raise "#{solved.point_count} points #{goal.sizes.values.sum} needed, solved atoms #{solved.atoms} doesn't match goal #{goal.sizes}"
        end
      end
      ans = !solved.nil?
      LOG.info "#{goali+1}: #{ans} #{goal}"
      LOG.info "\n#{solved}" if ans
      # # s = State.new(goal, Grid.new(goal.width, goal.height, Set.new, {}), atoms)
      # # s = Solver.new(goal, Grid.new(0, 0), atoms)
      # pool = Pool.new(atoms, goal.sizes)
      # trace = goal.width == 4
      # before = Time.now
      # if goals.size == 3 && goali == 2 then
      #   ans = false
      # elsif pool.marks_remaining > goal.width * goal.height then
      #   ans = iter_solve goal, Grid.new(goal.width, goal.height), pool, trace
      # else
      #   LOG.info "##{goali+1} can't possibly fit!"
      #   ans = false
      # end
      # after = Time.now
      #
      # # s = JigsawSolver.new(goal, Grid.new(0, 0), pool, Set.new)
      # # trace = true #(goal.sizes[4] == 3)
      # # ans = s.solvable? trace
      # # LOG.info "Cache size #{cache.size}"
      # # ans = s.solvable? library
      # # ans = s.solvable? cache, trace
      # LOG.info "#{ans} for ##{goali+1} #{goal} in #{Runner.new.format_duration(after-before)}"
      # STDOUT.flush
      # # LOG.info "library size: #{library.size}"
      # # LOG.info "Cache size: #{cache.size}"
      # # cache.levels.each do |k,v|
      # #   v.each do |g|
      # #     LOG.info "cached #{k} atoms #{g.atoms}"
      # #     LOG.info g
      # #   end
      # # end
      # # if pool.maybe_could_fit? Grid.new(goal.width, goal.height) then
      # #   ans = true # 408
      # # else
      # #   LOG.info "##{goali+1} can't possibly fit!"
      # #   ans = false
      # # end
      ans
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
      pts = (0..2).to_a.product((0..2).to_a).filter {|x,y| slice[1+y][x] == '#'}
      Grid.new 3, 3, pts, {num => 1}
    end
    goals = slices.last.map do |line|
      line =~ /(\d+)x(\d+): (.*)/
      # everything can be rotated, so normalize to width >= height
      # height, width = [$1.to_i, $2.to_i].minmax
      width, height = [$1, $2].map(&:to_i)
      targets = Hash.new(0)
      $3.split(' ').map(&:to_i).each_with_index {|x,i| targets[i] = x if x > 0}
      Goal.new width, height, targets.freeze
    end
    [atoms, goals]
  end
end

class Grid
  attr :width, :height, :points, :atoms

  def initialize w, h, pts=Set.new, ats=Hash.new
    @width = w
    @height = h
    @points = pts.to_set.freeze
    @atoms = ats.freeze
  end

  def dimensions
    [width, height]
  end

  def point_count
    points.size
  end

  def fits_with? o
    points.disjoint? o.points
  end

  def merge_with o
    if fits_with? o then
      Grid.new [width, o.width].max, [height, o.height].max,
        points.union(o.points), atoms.merge(o.atoms) {|k,a,b| a+b}
    else
      nil
    end
  end

  def offset x, y
    if x == 0 && y == 0 then
      self
    else
      Grid.new width+x.abs, height+y.abs, points.map {|a,b| [a+x, b+y]}, atoms
    end
  end

  def flip_horizontal
    Grid.new width, height, points.map {|x,y| [width-x-1, y]}, atoms
  end

  def flip_vertical
    Grid.new width, height, points.map {|x,y| [x, height-y-1]}, atoms
  end

  def rotate_deosil
    Grid.new height, width, points.map {|x,y| [height-y-1, x]}, atoms
  end

  def rotate_widdershins
    Grid.new height, width, points.map {|x,y| [y, width-x-1]}, atoms
  end

  def trim_margin
    if points.empty? then
      Grid.new 0, 0, Set.new, Hash.new
    else
      left = points.min_by {|x,y| x}[0]
      right = points.max_by {|x,y| x}[0]
      top = points.min_by {|x,y| y}[1]
      bottom = points.max_by {|x,y| y}[1]
      if left == 0 && right == width-1 && top == 0 && bottom == height-1 then
        self
      else
        Grid.new right-left+1, bottom-top+1, points.map {|x,y| [x-left, y-top]}, atoms
      end
    end
  end

  def family
    return @family if defined? @family
    s = Set.new [self, self.flip_vertical, self.flip_horizontal]
    f = Set.new s
    s.each {|g| 3.times {f.add(g = g.rotate_deosil)}}
    @family = f
  end

  def open_size
    width * height - point_count
  end

  def open_at_least size
    seen = Set.new
    spaces = []
    0.upto(width-1).each do |x|
      0.upto(height-1).each do |y|
        p = [x,y]
        unless points.include?(p) or seen.include?(p)
          seen.add p
          space = Set.new [p]
          q = [p]
          while o = q.pop
            ((o.first-1).clamp(0..)..(o.first+1).clamp(..width-1)).each do |xx|
              ((o.last-1).clamp(0..)..(o.last+1).clamp(..height-1)).each do |yy|
                n = [xx, yy]
                unless seen.include?(n) or points.include?(n)
                  seen.add n
                  space.add n
                  q << n
                end
              end
            end
          end
          spaces.push space if space.size >= size
        end
      end
    end
    # LOG.info "Open spaces: #{spaces.map(&:size)} for"
    # LOG.info self
    spaces.sort_by! &:size
    spaces
  end

  def trim_to_open_at_least size
    spaces = open_at_least size
    minx, maxx = spaces.flat_map {|s| s.map(&:first)}.minmax
    miny, maxy = spaces.flat_map {|s| s.map(&:last)}.minmax
    if minx == 0 && miny == 0 && maxx == width - 1 && maxy == height-1 then
      self
    else
      pts = points.map {|x,y| [x-minx, y-miny]}.reject {|x,y| x < 0 || y < 0}
      Grid.new width-minx, height-miny, pts, atoms
    end
  end

  def atoms_at_most? target
    # target.all? {|k,v| (atoms[k] || 0) <= v}
    atoms.all? {|k,v| v <= (target[k] || 0)}
  end

  def size_at_most? w, h
    width <= w && height <= h
  end

  def eql?(o)
    o.class == self.class && o.width == width && o.height == height &&
      o.points == points && o.atoms == atoms
  end
  alias == eql?

  def hash
    [self.class, width, height, points, atoms].hash
  end

  def to_s
    (0..height-1).map do |y|
      (0..width-1).map do |x|
        points.include?([x, y]) ? '#' : '.'
      end.join('')
    end.join("\n")
  end
end

Goal = Struct.new('Goal', :width, :height, :sizes) do |clazz|
  def dimensions
    [width, height]
  end

  def satisfied_by? grid
    ans = grid.width <= width && grid.height <= height &&
      sizes.all? {|k,v| (grid.atoms[k] || 0) >= v}
    if ans then
      LOG.info "satisfied #{self} with #{grid.atoms}"
      LOG.info grid.to_s
    end
    ans
  end

  def to_s
    "#{self.width}x#{self.height} #{(0..5).map {|i| self.sizes[i]}.join(" ")}"
  end
end

class Cache
  attr :levels

  def initialize
    @levels = Hash.new {|h,k| h[k] = Set.new}
  end

  def size
    levels.values.map(&:size).sum
  end

  def pieces_for goal, grid
    opts = Array.new
    open = (goal.width * goal.height) - grid.point_count
    remaining = goal.sizes.merge(grid.atoms) {|k,a,b| a-b}
    goal.height.downto(3) do |h|
      goal.width.downto(3) do |w|
        levels[[w, h]].each do |g|
          if g.point_count <= open and g.atoms_at_most? remaining then
            opts << g
          end
        end
      end
    end
    opts.sort_by {|g| g.atoms.values.sum}
    return opts
  end

  def add grid
    ps = grid.point_count
    grid = grid.trim_margin
    if grid.point_count != ps then
      LOG.info "Very suspicious"
      LOG.info grid
      raise "Questionable trim_margin behavior #{grid.points} #{grid.atoms}"
    end
    if grid.point_count / grid.atoms.values.sum < 5 then
      LOG.info "Suspicious!"
      LOG.info grid
      raise "Questionable points to atoms ratio: #{grid.points} #{grid.atoms}"
    end
    # LOG.info "caching #{grid.atoms}"
    # LOG.info grid
    grid.family.each do |g|
      if g.points.empty? then
        LOG.info "Questionable family generation #{g.atoms}"
        LOG.info g
        raise "Bad family"
      end
      levels[g.dimensions].add(g)
    end
  end
end

# class ByAtomsCache
#   attr :bycount
#
#   def initialize atoms
#     @bycount = Hash.new {|h,k| h[k] = Set.new}
#     atoms.each {|a| a.family.each {|x| @bycount[a.atoms].add x}}
#   end
#
#   def size
#     bycount.values.map(&:size).sum
#   end
#
#   def pieces_by_count maxw, maxh, counts
#     bycount[counts].filter {|g| g.width <= maxw && g.height <= maxh}
#   end
#
#   def add grid
#     grid = grid.trim_margin
#     grid.family.each {|g| levels[g.atoms].add(g)}
#   end
#
#   # def pieces_for goal, grid
#   #   opts = Array.new
#   #   open = (goal.width * goal.height) - grid.point_count
#   #   remaining = goal.sizes.merge(grid.atoms) {|k,a,b| a-b}
#   #   goal.height.downto(3) do |h|
#   #     goal.width.downto(3) do |w|
#   #       levels[[w, h]].each do |g|
#   #         if g.point_count <= open and g.atoms_at_most? remaining then
#   #           opts << g
#   #         end
#   #       end
#   #     end
#   #   end
#   #   opts.sort_by {|g| g.atoms.values.sum}
#   #   return opts
#   # end
# end

class Pool
  attr :atoms, :remaining, :checkouts

  def initialize atoms, sizes
    @atoms = atoms.freeze
    @remaining = Hash.new(0)
    sizes.each {|k,v| @remaining[k] = v} # avoid frozen
    @checkouts = 0
  end

  def marks_remaining
    remaining.map {|k,v| atoms[k].point_count * v}.sum
  end

  def available_nums
    remaining.keys.filter {|k| remaining[k] > 0}
  end

  def min_atom_size
    available_nums.map {|n| atoms[n].point_count}.min
  end

  def maybe_could_fit? grid
    min, max = available_nums.map {|n| atoms[n].point_count}.minmax
    spaces = grid.open_at_least min
    spaces.any? {|s| s.size >= max} and spaces.map(&:size).sum >= marks_remaining
  end

  def take atomnum
    if remaining[atomnum] == 0 then
      raise("All out of #{atomnum}")
    else
      @checkouts += 1
      remaining[atomnum] -= 1
      raise("Unknown atom #{atomnum}") unless atoms[atomnum]
      yield(atoms[atomnum])
      remaining[atomnum] += 1
    end
  end

  def replace atomnum
    remaining[atomnum] += 1
  end
end

def simple_solve goal, atoms
  needed = goal.sizes.map {|k,v| atoms[k].point_count * v}.sum
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
    g = g.merge_with a.offset(x, y)
    x += 3
    if x + 2 >= goal.width then
      x = 0
      y += 3
      break if y + 2 >= g.height
    end
  end
  if avail.empty? then g else nil end
end

def exhaustive_solve goal, atoms
  needed = goal.sizes.map {|k,v| atoms[k].point_count * v}.sum
  if needed > goal.width * goal.height then
    return nil
  end
  expanded = Array.new
  goal.sizes.each {|k,v| v.times {expanded.push atoms[k]}}
  expanded.shuffle!
  seen = Set.new
  expanded.permutation(expanded.size) do |avail|
    unless seen.include? avail
      # LOG.info "Permutation\n#{avail.join("\n===\n")}"
      seen.add(avail)
      g = recursive_fit Grid.new(goal.width, goal.height), avail, Set.new
      LOG.info "Solved after #{seen.size} permutations #{goal}"
      return g unless g.nil?
    end
  end
  nil
end

def recursive_fit grid, avail, bad, hits=[0]
  return grid if avail.empty?
  badkey = [grid, avail.to_set]
  if bad.include? badkey then
    hits[0] += 1
    return nil
  end
  a = avail.last
  open = grid.open_at_least a.point_count
  # LOG.info "Filling #{open} with\n#{a.family.join("\n===\n")}"
  if open.map {|s| s.size}.sum < avail.map {|a| a.point_count}.sum then
    return nil
  end
  open.each do |points|
    points.sort.each do |p|
      if p[0] + 2 < grid.width and p[1] + 2 < grid.height then
        # TODO only putting the top-left atom corner on an open space misses
        # opportunities to overlay an empty corner on a covered space.
        # Add a frontier method to Grid that returns just squares that have at
        # least one and fewer than 9 full or off-the-board points in the 'hood.
        if p[0] == 0 || p[1] == 0 || grid.points.intersect?([
            [p[0]-1,p[1]-1], [p[0],p[1]-1], [p[0]+1,p[1]-1],
            [p[0]-1,p[1]],   [p[0],p[1]],   [p[0]+1,p[1]],
            [p[0]-1,p[1]+1], [p[0],p[1]+1], [p[0]+1,p[0]+1],
        ]) then
          a.family.each do |f|
            o = f.offset p[0], p[1]
            m = grid.merge_with o
            unless m.nil?
              g = recursive_fit m, avail[...-1], bad, hits
              return g unless g.nil?
            end
          end
        end
      end
    end
  end
  if bad.size % 1000 == 0
    LOG.info "Caching bad state #{bad.size + 1}, cache hits #{hits[0]}"
  end
  bad.add badkey
  nil
end

# TODO: Floodfill the empty spaces, throw out any that are too small for an atom
# and then see if mark count is exceeded.
# Also consider forming a grid around the open block and trying to fill that.

def iter_solve goal, grid, pool, trace=false, x=0, y=0, bad=Set.new
  if pool.marks_remaining == 0 then
    LOG.info "Solved #{goal.width}x#{goal.height} #{goal.sizes} with #{grid.atoms}"
    LOG.info grid
    raise("Suspicious grid, #{goal.sizes} != #{grid.atoms}") unless goal.sizes == grid.atoms
    # raise("Suspicious grid, #{goal} isn't #{grid.width}x#{grid.height}") unless [goal.width, goal.height] == grid.dimensions
    return true
  end
  if x+2 >= grid.width or grid.width < 3 or grid.height < 3 then
    bad.add grid
    # if grid.dimensions == goal.dimensions then
    #   LOG.info "Off the edge #{goal.sizes} #{grid.atoms}"
    #   LOG.info grid
    # end
    return false
  end
  if grid.point_count > pool.marks_remaining then
    unless pool.maybe_could_fit? grid then
      bad.add grid
      # if grid.dimensions == goal.dimensions then
      #   LOG.info "Can't fit remaining #{goal.sizes} #{grid.atoms} #{pool.remaining}"
      #   LOG.info "Remaining #{pool.marks_remaining} sizes #{grid.open_at_least(7).map(&:size)}"
      #   LOG.info grid
      # end
      return false
    end
    trimmed = grid.trim_to_open_at_least pool.min_atom_size
    if trimmed.width < 3 or trimmed.height < 3 then
      bad.add grid
      return false
    end
    if trimmed.dimensions != grid.dimensions then
      # LOG.info "Replaced #{grid.atoms}"
      # LOG.info grid
      # LOG.info "With #{trimmed.atoms}"
      # LOG.info trimmed
      grid = trimmed
      x = 0
      y = 0
    end
  end
  if bad.include? bad then
    return false
  end
  if trace or pool.checkouts % 100000 == 0 && pool.checkouts > 0 then
    LOG.info "At (#{x},#{y}): #{grid.atoms} checkouts #{pool.checkouts}"
    LOG.info grid
  end
  nexty = y+1
  nextx = x
  if nexty+2 >= grid.height then
    nexty = 0
    nextx = x+1
  end
  pool.available_nums.shuffle.each do |anum|
    pool.take anum do |atom|
      atom.family.each do |a|
        g = grid.merge_with a.offset(x, y)
        if g then
          if trace then
            LOG.info "Trying #{anum} at #{x},#{y}"
            LOG.info g
          end
          return true if iter_solve(goal, g, pool, trace, nextx, nexty, bad)
        end
      end
    end
  end
  iter_solve goal, grid, pool, trace, nextx, nexty, bad
end

JigsawSolver = Struct.new('JigsawSolver', :goal, :grid, :pool, :tried) do |clazz|
  def missing_marks
    goal.sizes.map {|k,v| v - (grid.atoms[k]||0) * pool.atoms[k].point_count}.sum
  end

  def solvable? trace=false
    if goal.satisfied_by? grid then
      true
    elsif missing_marks > pool.marks_remaining
      false
    else
      # tried.add(grid)
      catch (:found) do
        pool.available_nums.each do |anum|
          pool.take(anum) do |atom|
            atom.family.each do |p|
              # if trace then
              #   LOG.info "Considering #{p.atoms}"
              #   LOG.info p
              # end
              0.upto(grid.height.clamp(0..goal.height-p.height)) do |y|
                0.upto(grid.width.clamp(0..goal.width-p.width)) do |x|
                  g = grid.merge_with(p.offset(x, y))
                  if g then #&& !tried.include?(g) then
                    # if trace then
                    #   LOG.info "Up to #{g.atoms} from #{p.atoms}"
                    #   LOG.info g
                    # end
                    throw :found, true if JigsawSolver.new(goal, g, pool, tried).solvable?
                  end
                end
              end
            end
          end
        end
        false
      end
    end
  end
end

Solver = Struct.new('Solver', :goal, :grid, :atomics) do |clazz|
  def missing_marks
    goal.sizes.map {|k,v| v - (grid.atoms[k]||0) * atomics[k].point_count}.sum
  end

  def remaining_space
    (goal.width * goal.height) - grid.point_count
  end

  def solvable? cache, trace=false, tried=Set.new
    if goal.satisfied_by? grid then
      true
    elsif missing_marks > remaining_space
      false
    else
      tried.add(grid)
      catch(:found) do
        cache.pieces_for(goal, grid).each do |p|
          if trace then
            LOG.info "Trace #{grid.atoms}"
            LOG.info grid
            LOG.info "Considering #{p.atoms}"
            LOG.info p
          end
          0.upto(grid.height.clamp(0..goal.height-p.height)) do |y|
            0.upto(grid.width.clamp(0..goal.width-p.width)) do |x|
              g = grid.merge_with(p.offset(x, y))
              if g && !tried.include?(g) then
                if trace then
                  LOG.info "Up to #{g.atoms} from #{p.atoms}"
                  LOG.info g
                end
                cache.add g
                throw :found, true if Solver.new(goal, g, atomics).solvable?(cache, trace, tried)
              end
            end
          end
        end
        false
      end
    end
  end
end

State = Struct.new('State', :goal, :grid, :atomics) do |clazz|
  def missing_marks
    (0...goal.sizes.size).map {|i| goal.sizes[i] - (grid.atoms[i]||0) * atomics[i].point_count}.sum
  end

  def solvable? library, tried=Set.new
    tried.add(grid)
    if goal.satisfied_by? grid then
      true
    elsif missing_marks > grid.open_size
      false
    else
      opts = library.filter do |g|
        g.size_at_most?(goal.width, goal.height) &&
          g.atoms_at_most?(goal.sizes) && g.point_count <= grid.open_size
      end.sort_by do |g|
        [
          (0...goal.sizes.size).map {|i| (goal.sizes[i]-(g.atoms[i]||0)).abs}.sum,
          g.width * g.height,
          -g.open_size
        ]
      end
      opts.any? do |g|
        if grid.fits_with? g then
          made = grid.merge_with g
          unless tried.include? made then
            # library.add(made.trim_margin)
            State.new(goal, made, atomics).solvable? library, tried
          end
        else
          catch(:found) do
            (0..grid.width.clamp(0..goal.width-g.width)).map do |x|
              (0..grid.height.clamp(0..goal.height-g.height)).map do |y|
                if x + y > 0 then
                  f = g.offset x, y
                  if grid.fits_with? f then
                    made = grid.merge_with f
                    if made.atoms_at_most? goal.sizes and !(tried.include? made) then
                      trimmed = made.trim_margin
                      library.add(trimmed) if trimmed.width * trimmed.height <= goal.width * goal.height / 2
                      # if library.size % 100 == 0
                      if tried.size % 100 == 0
                        # LOG.info "library is now #{library.size} at #{x}, #{y} atoms #{made.atoms} vs #{goal.sizes}"
                        LOG.info "tried is #{tried.size} library #{library.size} at #{x}, #{y} atoms #{made.atoms} vs #{goal.sizes}"
                        LOG.info made
                      end
                      if State.new(goal, made, atomics).solvable? library, tried then
                        throw :found, true
                      end
                    end
                  end
                end
              end
            end
            false
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative '../runner.rb'
  exit Runner.new.run_day(Day12.new, ARGV)
end
