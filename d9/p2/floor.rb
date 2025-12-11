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
    self.green_rectangles = ring.extract_rectangles
    self.ring = nil
  end

  def biggest_red_tile_defined_rectangle_containing_all_green_or_red_tiles
    rectangles.each.with_index do |rectangle, index|
      puts "processing #{index}: #{rectangle}"

      green_rectangles.each do |green_rectangle|
        puts "considering green rectangle #{green_rectangle}"

        rectangles_to_break = [rectangle]

        loop do
          if rectangles_to_break.empty?
            return rectangle
          end

          rectangle_to_break = rectangles_to_break.shift

          result = green_rectangle.remove_overlapping_pieces(rectangle_to_break)

          if result == rectangle_to_break
            # no progress made, move on to next green rectangle
            break
          end

          to_add = [*result]
          to_add.each { puts "broke into #{to_add.inspect}" }

          to_add.each { rectangles_to_break << it }
        end
      end
    end

    nil
  end

  def rectangles
    return @rectangles if @rectangles

    rectangles = []

    points_size = points.size

    0.upto(points_size - 2) do |corner1_index|
      corner1 = points[corner1_index]
      corner1_index.upto(points_size - 1) do |corner2_index|
        corner2 = points[corner2_index]

        rectangles << Rectangle.new(corner1, corner2)
      end
    end

    rectangles.sort_by!(&:area)
    rectangles.reverse!

    @rectangles = rectangles
  end
end
