class Joltages
  attr_accessor :joltage_levels

  def initialize(joltage_levels)
    self.joltage_levels = joltage_levels
  end

  def ==(other)
    joltage_levels == other.joltage_levels
  end

  def dec(i) = joltage_levels[i] -= 1
  def dup = Joltages.new(joltage_levels.dup)
  def any?(&) = joltage_levels.any?(&)
  def all?(&) = joltage_levels.all?(&)
  def sum = joltage_levels.sum
  def done? = joltage_levels.all?(&:zero?)

  def any_over?(target)
    target_levels = target.joltage_levels

    joltage_levels.each.with_index.any? do |level, index|
      level > target_levels[index]
    end
  end

  def [](index) = joltage_levels[index]

  def each(&) = joltage_levels.each(&)
  def size = joltage_levels.size
  def to_s ="{#{joltage_levels.join(",")}}"
  def inspect = to_s
end
