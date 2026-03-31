class Present
  attr_accessor :index, :spaces

  def initialize(index, spaces)
    self.index = index
    self.spaces = spaces
  end

  def flip
    Present.new(index, spaces.map(&:reverse))
  end

  def rotate
    rotated_spaces = (0...width).map do |column|
      spaces.map { |row| row[column] }.reverse.join
    end

    Present.new(index, rotated_spaces)
  end

  def width = spaces.first.size

  def to_s
    spaces.join("\n")
  end
end
