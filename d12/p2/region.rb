class Region
  class FillError < StandardError; end
  class OutOfBoundsError < FillError; end
  class AlreadyFilledError < FillError; end

  NINE_BY_NINE_PRESENT = PresentShape.new([
                                            [true, true, true],
                                            [true, true, true],
                                            [true, true, true]
                                          ])

  attr_accessor :height, :width, :spaces, :last_rotated_clockwise

  def initialize(height:,
                 width:,
                 last_rotated_clockwise: nil,
                 spaces: Array.new(height) { Array.new(width, false) })
    self.last_rotated_clockwise = last_rotated_clockwise
    self.height = height
    self.width = width

    self.spaces = spaces
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

    # y first since we're row-wise
    spaces[y][x] = true
  end

  def shape_out_of_bounds?(present_shape, x, y)
    return true if width < 3 || height < 3

    present_shape.each_filled_space do |i, j|
      return true if point_out_of_bounds?(x + i, y + j)
    end

    false
  end

  def point_out_of_bounds?(x, y)
    x >= width || y >= height || x < 0 || y < 0
  end

  # y first since we're row-wise
  def filled?(x, y)
    spaces[y][x]
  end

  def available_area
    @available_area ||= spaces.sum do |column|
      column.count { !it }
    end
  end

  def non_empty_row_count
    count = 0
    i = 0

    loop do
      row = spaces[i]
      break unless row
      break unless row.any? { it }

      count += 1
      i += 1
    end

    count
  end

  def candidate_starting_points(present_shape, x = 0, y = 0, &block)
    return if width < 3 || height < 3
    return if shape_out_of_bounds?(present_shape, x, y)

    if will_fit_at?(present_shape, x, y)
      block.call(x, y)

      return if all_available_at?(x, y)
    end

    candidate_starting_points(present_shape, x + 1, y, &block)
    if y < 1
      candidate_starting_points(present_shape, x, y + 1, &block)
    end
  end

  def trim!(present_counts)
    if can_trim?(present_counts)
      self.height -= 1
      spaces.shift
      # TODO: this checks 4 trims when we can at most trim three times
      trim!(present_counts)
    end
  end

  def can_trim?(present_counts)
    if present_counts.values.all? { |i| i <= 0 }
      binding.pry
    end
    return false if height < 3

    present_counts.each_pair do |index, count|
      next if count.zero?

      present_shape = PresentShape[index]

      present_shape.variants.each do |present_variant|
        0.upto(width - 3).each do |x|
          if will_fit_at?(present_variant, x, 0)
            return false
          end
        end
      end
    end

    true
  end

  def to_s
    "#{width}x#{height}\n" + spaces.map do |row|
      row.map { it ? "#" : "." }.join
    end.join("\n")
  end

  def dup
    super.tap do |new_region|
      new_region.spaces = spaces.map(&:dup)
    end
  end

  def normalize(rotations = nil)
    if rotations.nil? && last_rotated_clockwise
      rotations = 2
    end

    if width > height
      rotated_spaces = spaces

      rotated_spaces = (0...width).map do |column|
        rotated_spaces.map { |row| row[column] }.reverse
      end

      if rotations && rotations >= 0
        new_region = Region.new(width: height,
                                height: width,
                                spaces: rotated_spaces,
                                last_rotated_clockwise:)

        new_region.normalize(rotations - 1)
      else
        Region.new(width: height,
                   height: width,
                   spaces: rotated_spaces,
                   last_rotated_clockwise: !last_rotated_clockwise)
      end
    else
      self
    end
  end
end
