class PresentShape
  attr_accessor :index, :spaces

  def initialize(index, spaces)
    self.index = index
    self.spaces = spaces
  end

  def flip
    self.class.new(index, spaces.map(&:reverse))
  end

  def rotate
    rotated_spaces = (0...width).map do |column|
      spaces.map { |row| row[column] }.reverse
    end

    self.class.new(index, rotated_spaces)
  end

  def width = spaces.first.size

  def to_s
    spaces.map do |column|
      column.map { it ? "#" : "." }.join
    end.join("\n")
  end

  def each_filled_space
    spaces.each_with_index do |column, x|
      column.each_with_index do |filled, y|
        if filled
          yield x, y
        end
      end
    end
  end
end
