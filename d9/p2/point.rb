class Point
  include Comparable

  def self.[](...) = new(...)

  attr_accessor :x, :y

  def initialize(x, y)
    self.x = x
    self.y = y

    freeze
  end

  def to_s = "(#{x},#{y})"

  def ==(other)
    if other.is_a?(Point)
      other.x == x && other.y == y
    end
  end

  def eql?(other) = self == other

  def hash
    [x, y].hash
  end

  def <=>(other)
    cmp = y <=> other.y
    cmp.zero? ? x <=> other.x : cmp
  end

  def dup = super.freeze
end
