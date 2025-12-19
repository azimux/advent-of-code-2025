require_relative "ring"

class Floor
  attr_accessor :points, :filled_tiles, :red_tiles_set, :green_rectangles, :ring

  def initialize(points)
    self.points = points
    self.ring = Ring.new(points)
    self.red_tiles_set = points.to_set

    extract_green_rectangles
  end

  def extract_green_rectangles
    self.green_rectangles = ring.extract_rectangles.sort_by(&:x1)
    self.ring = nil
  end

  def find_green_rectangles_for(red_rectangle)
    candidate_green_rectangles = []

    x1 = red_rectangle.x1
    x2 = red_rectangle.x2
    y1 = red_rectangle.y1
    y2 = red_rectangle.y2

    green_rectangles.each do |green_rectangle|
      break if green_rectangle.x1 > x2

      if green_rectangle.x1.between?(x1, x2) ||
         green_rectangle.x2.between?(x1, x2) ||
         (green_rectangle.x1 < x1 && green_rectangle.x2 > x2)
        candidate_green_rectangles << green_rectangle
      end
    end

    candidate_green_rectangles.reject do |candidate_green_rectangle|
      candidate_green_rectangle.y2 < y1 || candidate_green_rectangle.y1 > y2
    end
  end

  def biggest_red_rectangle_containing_all_green_tiles
    total_rectangles = red_rectangles.size

    red_rectangles.each.with_index do |red_rectangle, index|
      # puts "processing #{index + 1}/#{total_rectangles} #{rectangle}"

      red_rectangles_to_break = [red_rectangle]

      find_green_rectangles_for(red_rectangle).each do |green_rectangle|
        if red_rectangles_to_break.empty?
          return red_rectangle
        end

        red_rectangle_to_break = red_rectangles_to_break.shift

        result = green_rectangle.remove_overlapping_pieces(red_rectangle_to_break)

        if result == red_rectangle_to_break
          # no progress made, move on to next green rectangle
          red_rectangles_to_break << result
        else
          to_add = [*result]
          to_add.each { red_rectangles_to_break << it }

          begin
            if to_add.size != to_add.uniq.size
              binding.pry
            end
          rescue => e
            binding.pry
            raise
          end
        end
      end
    end

    nil
  end

  def red_rectangles
    return @red_rectangles if @red_rectangles

    red_rectangles = []

    points_size = points.size

    0.upto(points_size - 2) do |corner1_index|
      corner1 = points[corner1_index]

      (corner1_index + 1).upto(points_size - 1) do |corner2_index|
        corner2 = points[corner2_index]

        red_rectangles << Rectangle.new(corner1, corner2)
      end
    end

    red_rectangles.sort_by!(&:area)
    red_rectangles.reverse!

    @red_rectangles = red_rectangles
  end
end
