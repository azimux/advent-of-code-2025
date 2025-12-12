require_relative "point"
require_relative "line"

class Rectangle
  include Comparable

  attr_reader :x1, :x2, :y1, :y2

  def initialize(corner1, corner2)
    @x1 = corner1.x
    @x2 = corner2.x
    @y1 = corner1.y
    @y2 = corner2.y

    if @x1 > @x2
      @x1, @x2 = @x2, @x1
    end

    if @y1 > @y2
      @y1, @y2 = @y2, @y1
    end
  end

  def area
    (x2 - x1 + 1) * (y2 - y1 + 1)
  end

  def ul = @ul ||= Point.new(x1, y1)
  def ur = @ur ||= Point.new(x2, y1)
  def bl = @bl ||= Point.new(x1, y2)
  def br = @br ||= Point.new(x2, y2)
  def points = @points ||= [ul, ur, bl, br].freeze

  def lines
    @lines ||= [
      Line.new(ul, ur),
      Line.new(ur, br),
      Line.new(bl, br),
      Line.new(ul, bl)
    ].freeze
  end

  def overlaps?(other)
    lines.any? do |line|
      other.lines.any? do |other_line|
        line.intersects?(other_line)
      end
    end
  end

  def remove_overlapping_pieces(rectangle_to_break)
    contained_points, uncontained_points = rectangle_to_break.points.partition do |p|
      contains?(p)
    end

    case contained_points.size
    when 0
      our_points_contained_by_rectangle_to_break = points.select do |p|
        rectangle_to_break.contains?(p)
      end.sort

      case our_points_contained_by_rectangle_to_break.size
      when 0
        if overlaps?(rectangle_to_break)
          if y1 < rectangle_to_break.y1
            # we're the tall skinny one, they're the flat one
            [
              Rectangle.new(rectangle_to_break.ul, Point[x1 - 1, rectangle_to_break.y2]),
              Rectangle.new(Point[x2 + 1, rectangle_to_break.y1], rectangle_to_break.br)
            ]
          else
            # we're the flat one, they're the tall skinny one
            [
              Rectangle.new(rectangle_to_break.ul, Point[rectangle_to_break.x2, y1 - 1]),
              Rectangle.new(Point[rectangle_to_break.x1, y2 + 1], rectangle_to_break.br)
            ]
          end
        else
          rectangle_to_break
        end
      when 2
        case our_points_contained_by_rectangle_to_break
        when [ul, ur] # top
          [
            # left piece
            Rectangle.new(rectangle_to_break.ul, Point[x1 - 1, rectangle_to_break.y2]),
            # middle top
            Rectangle.new(Point[ul.x, ul.y - 1], Point[x2, rectangle_to_break.y1]),
            # right piece
            Rectangle.new(rectangle_to_break.ur, Point[x2 + 1, rectangle_to_break.y2])
          ]
        when [ur, br] # right
          [
            # top piece
            Rectangle.new(rectangle_to_break.ul, Point[rectangle_to_break.x2, y1 - 1]),
            # middle right
            Rectangle.new(Point[x2 + 1, y2], Point[rectangle_to_break.x2, y1]),
            # bottom piece
            Rectangle.new(rectangle_to_break.bl, Point[rectangle_to_break.x2, y2 + 1])
          ]
        when [ul, bl] # left
          [
            # top piece
            Rectangle.new(rectangle_to_break.ul, Point[rectangle_to_break.x2, y1 - 1]),
            # middle left
            Rectangle.new(Point[x1 - 1, y2], Point[rectangle_to_break.x1, y1]),
            # bottom piece
            Rectangle.new(rectangle_to_break.bl, Point[rectangle_to_break.x2, y2 + 2])
          ]
        when [bl, br] # bottom
          [
            # left piece
            Rectangle.new(rectangle_to_break.ul, Point[x1 - 1, rectangle_to_break.y2]),
            # middle bottom
            Rectangle.new(Point[bl.x, bl.y + 1], Point[x2, rectangle_to_break.y2]),
            # right piece
            Rectangle.new(rectangle_to_break.ur, Point[x2 + 1, rectangle_to_break.y2])
          ]
        else
          raise "wtf"
        end
      when 4
        [
          # top row
          Rectangle.new(rectangle_to_break.ul, Point[x1 - 1, y1 - 1]),
          Rectangle.new(Point[x2, rectangle_to_break.y1], Point[x1, y1 - 1]),
          Rectangle.new(rectangle_to_break.ur, Point[x2 + 1, y1 - 1]),

          # middle row
          Rectangle.new(Point[rectangle_to_break.x1, y2], Point[x1 - 1, y1]),
          Rectangle.new(Point[x2 + 1, y1], Point[rectangle_to_break.x2, y2]),

          # bottom row
          Rectangle.new(rectangle_to_break.bl, Point[x1 - 1, y2 + 1]),
          Rectangle.new(Point[x1, y2 + 1], Point[x2, rectangle_to_break.y2]),
          Rectangle.new(Point[x2 + 1, y2 + 1], rectangle_to_break.br)
        ]
      end
    when 1
      corner_other_contains = points.find { |p| rectangle_to_break.contains?(p) }

      uncontained_points.map do |up|
        Rectangle.new(corner_other_contains, up)
      end

      case corner_other_contains
      when ul
        [
          # diagonal (upper left)
          Rectangle.new(rectangle_to_break.ul, Point[x1 - 1, y1 - 1]),
          # upper right
          Rectangle.new(rectangle_to_break.ur, Point[x1, y1 - 1]),
          # lower left
          Rectangle.new(rectangle_to_break.bl, Point[x1, y1 - 1])
        ]
      when ur
        [
          # diagonal (upper right)
          Rectangle.new(rectangle_to_break.ur, Point[x2 + 1, y1 - 1]),
          # upper left
          Rectangle.new(rectangle_to_break.ul, Point[x2, y1 - 1]),
          # bottom right
          Rectangle.new(rectangle_to_break.br, Point[x2 + 1, y1])
        ]
      when bl
        [
          # diagonal (lower left)
          Rectangle.new(rectangle_to_break.bl, Point[x1 - 1, y2 + 1]),
          # upper left
          Rectangle.new(rectangle_to_break.ul, Point[x1 - 1, y2]),
          # bottom right
          Rectangle.new(rectangle_to_break.br, Point[x1, y2 + 1])
        ]
      when br
        [
          # diagonal (bottom right)
          Rectangle.new(rectangle_to_break.br, Point[x2 + 1, y2 + 1]),
          # upper right
          Rectangle.new(rectangle_to_break.ur, Point[x2 + 1, y2]),
          # bottom left
          Rectangle.new(rectangle_to_break.bl, Point[x2, y2 + 1])
        ]
      else
        raise "wtf"
      end
    when 2
      # 1r
      # will contain the two uncontained points.
      up1, up2 = uncontained_points
      cp1 = contained_points.first

      corner1 = up1

      if up1.x == up2.x
        # we contain a vertical edge
        x = if cp1.x < up1.x
              # we contain the left edge of the rectangle_to_break
              x2 + 1
            else
              # we contain the right edge of the rectangle_to_break
              x1 - 1
            end

        corner2 = Point[x, up2.y]
      else
        # we contain a horizontal edge
        y = if cp1.y < up1.y
              # we contain the top edge of the rectangle_to_break
              y2 + 1
            else
              # we contain the bottom edge of the rectangle_to_break
              y1 - 1
            end

        corner2 = Point[up2.x, y]
      end

      Rectangle.new(corner1, corner2)
    end
  end

  def contains?(point)
    point.x.between?(x1, x2) && point.y.between?(y1, y2)
  end

  def to_s = "R#{ul}-#{br}"

  def ==(other)
    other.is_a?(Rectangle) &&
      x1 == other.x1 &&
      x2 == other.x2 &&
      y1 == other.y1 &&
      y2 == other.y2
  end

  def hash = [x1, x2, y1, y2]
  def eql?(other) = self == other

  def <=>(other)
    [x1, x2, y1, y2] <=> [other.x1, other.x2, other.y1, other.y2]
  end
end
