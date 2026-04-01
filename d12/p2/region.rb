class Region
  class FillError < StandardError; end
  class OutOfBoundsError < FillError; end
  class AlreadyFilledError < FillError; end

  attr_accessor :height, :width, :spaces

  def initialize(height:, width:)
    self.height = height
    self.width = width

    self.spaces = Array.new(width) { Array.new(height, false) }
  end

  def add_present_shape_at(present_shape, x, y)
    present_shape.each_filled_space do |(i, j)|
      fill_at(x + i, y + j)
    end
  end

  def fill_at(x, y)
    if out_of_bounds?(x, y)
      raise OutOfBoundsError, "Out of bounds! #{x}, #{y}"
    end

    if filled?(x, y)
      raise AlreadyFilledError, "Already filled! #{x}, #{y}"
    end

    spaces[x][y] = true
  end

  def out_of_bounds?(x, y) = x >= width || y >= height
  def filled?(x, y) = spaces[x][y]
end
