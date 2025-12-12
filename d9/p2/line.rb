class Line
  attr_accessor :point1, :point2

  def initialize(point1, point2)
    if point1 < point2
      self.point1 = point1
      self.point2 = point2
    else
      self.point2 = point1
      self.point1 = point2
    end
  end

  def intersects?(other_line)
    if vertical? && other_line.vertical?
      if point1.x == other_line.point1.x
        y_range.overlap?(other_line.y_range)
      end
    elsif horizontal? && other_line.horizontal?
      if point1.y == other_line.point1.y
        x_range.overlap?(other_line.x_range)
      end
    elsif vertical?
      # Point.new(point1.x, other_line.point1.y)
      other_line.x_range.member?(point1.x) &&
        y_range.member?(other_line.point1.y)
    else
      other_line.y_range.member?(point1.y) &&
        x_range.member?(other_line.point1.x)
    end
  end

  # Only works with right-angle lines and if we already know we intersect
  def intersects_at(other_line)
    if horizontal?
      Point.new(point1.y, other_line.point1.x)
    else
      Point.new(other_line.point1.x, point1.y)
    end
  end

  def horizontal?
    return @horizontal if defined?(@horizontal)

    @horizontal = point1.y == point2.y
  end

  def vertical?
    return @vertical if defined?(@vertical)

    @vertical = point1.x == point2.x
  end

  def y_range = @y_range ||= (point1.y..point2.y)
  def x_range = @x_range ||= (point1.x..point2.x)
end
