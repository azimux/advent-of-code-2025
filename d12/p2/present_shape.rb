class PresentShape
  @all = {}

  class << self
    attr_reader :all

    def []=(index, present_shape)
      all[index] = present_shape
    end

    def [](index) = all[index]
  end

  attr_accessor :spaces

  def initialize(spaces)
    self.spaces = spaces
  end

  def flip
    self.class.new(spaces.map(&:reverse))
  end

  def rotate
    rotated_spaces = (0...width).map do |column|
      spaces.map { |row| row[column] }.reverse
    end

    self.class.new(rotated_spaces)
  end

  def width = spaces.first.size

  def to_s
    spaces.map do |row|
      row.map { it ? "#" : "." }.join
    end.join("\n")
  end

  def each_filled_space
    spaces.each_with_index do |row, x|
      row.each_with_index do |filled, y|
        if filled
          yield x, y
        end
      end
    end
  end

  def each_variant
    variants.each { yield it }
  end

  def variants
    return @variants if @variants

    @variants = []

    seen = Set.new
    seen << spaces

    shape = self

    @variants << self

    3.times do
      shape = shape.rotate

      new_spaces = shape.spaces

      unless seen.include?(new_spaces)
        seen << new_spaces
        @variants << shape
      end
    end

    shape = flip

    new_spaces = shape.spaces

    unless seen.include?(new_spaces)
      seen << new_spaces
      @variants << shape
    end

    3.times do
      shape = shape.rotate

      new_spaces = shape.spaces

      unless seen.include?(new_spaces)
        seen << new_spaces
        @variants << shape
      end
    end

    @variants
  end

  def area
    @area ||= spaces.sum do |row|
      row.count { it }
    end
  end
end
