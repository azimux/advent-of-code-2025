class Button
  attr_accessor :joltages_to_increment

  def initialize(joltages_to_increment)
    self.joltages_to_increment = joltages_to_increment
  end

  def push(joltages)
    joltages_to_increment.each { joltages.inc(it) }
  end

  def include?(joltage_index) = joltages_to_increment.include?(joltage_index)

  def to_s ="(#{joltages_to_increment.join(",")})"
  def inspect = to_s
end
