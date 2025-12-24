class Joltages
  attr_accessor :joltage_levels

  def initialize(joltage_levels)
    self.joltage_levels = joltage_levels
  end

  def ==(other)
    joltage_levels == other.joltage_levels
  end

  def inc(i)
    joltage_levels[i] += 1
  end

  def any_over?(target)
    target_levels = target.joltage_levels

    joltage_levels.each.with_index.any? do |level, index|
      level > target_levels[index]
    end
  end

  def each(&) = joltage_levels.each(&)
  def size = joltage_levels.size
  def to_s ="{#{joltage_levels.join(",")}}"
  def inspect = to_s
end
