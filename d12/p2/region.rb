class Region
  class FillError < StandardError; end
  class OutOfBoundsError < FillError; end
  class AlreadyFilledError < FillError; end

  NINE_BY_NINE_PRESENT = PresentShape.new([
                                            [true, true, true],
                                            [true, true, true],
                                            [true, true, true]
                                          ])
  attr_accessor :height, :width, :spaces

  def initialize(height:, width:)
    self.height = height
    self.width = width

    self.spaces = Array.new(width) { Array.new(height, false) }
  end

  def add_present_shape_at(present_shape, x, y)
    present_shape.each_filled_space do |i, j|
      fill_at(x + i, y + j)
    end
  end

  def will_fit_at?(present_shape, x, y)
    return false if shape_out_of_bounds?(present_shape, x, y)

    present_shape.each_filled_space do |i, j|
      return false if filled?(x + i, y + j)
    end

    true
  end

  def all_available_at?(x, y)
    will_fit_at?(NINE_BY_NINE_PRESENT, x, y)
  end

  def fill_at(x, y)
    if point_out_of_bounds?(x, y)
      raise OutOfBoundsError, "Out of bounds! #{x}, #{y}"
    end

    if filled?(x, y)
      raise AlreadyFilledError, "Already filled! #{x}, #{y}"
    end

    spaces[x][y] = true
  end

  def shape_out_of_bounds?(present_shape, x, y)
    present_shape.each_filled_space do |i, j|
      return true if point_out_of_bounds?(x + i, y + j)
    end

    false
  end

  def point_out_of_bounds?(x, y) = x >= width || y >= height
  def filled?(x, y) = spaces[x][y]

  def available_area
    @available_area ||= spaces.sum do |column|
      column.count { !it }
    end
  end

  def candidate_starting_points(present_shape, x = 0, y = 0, &block)
    return if shape_out_of_bounds?(present_shape, x, y)

    if will_fit_at?(present_shape, x, y)
      block.call(x, y)

      return if all_available_at?(x, y)
    end

    candidate_starting_points(present_shape, x + 1, y, &block)
    candidate_starting_points(present_shape, x, y + 1, &block)
  end

  def dup
    super.tap do |new_region|
      new_region.spaces = spaces.map(&:dup)
    end
  end
end
