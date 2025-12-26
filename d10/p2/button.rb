class Button
  attr_accessor :joltages_to_increment

  def initialize(joltages_to_increment)
    self.joltages_to_increment = joltages_to_increment
  end

  def push(joltages)
    joltages_to_increment.each { joltages.dec(it) }
  end

  def joltages_size = joltages_to_increment.size
  def include?(joltage_index) = joltages_to_increment.include?(joltage_index)
  def to_s ="(#{joltages_to_increment.join(",")})"
  def inspect = to_s

  def hash = joltages_to_increment.hash

  def ==(other)
    other.is_a?(Button) && other.joltages_to_increment == joltages_to_increment
  end

  def eql?(other)= self == other
end
