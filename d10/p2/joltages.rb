class Joltages
  attr_accessor :joltage_levels

  def initialize(joltage_levels)
    binding.pry unless joltage_levels
    self.joltage_levels = joltage_levels
  end

  def ==(other)
    joltage_levels == other.joltage_levels
  end

  def inc(i)
    joltage_levels[i] += 1
  rescue => e
    binding.pry
    raise
  end

  def any_over?(target)
    target_levels = target.joltage_levels

    joltage_levels.each.with_index.any? do |level, index|
      target_levels[index] > level
    end
  end

  def each(&) = joltage_levels.each(&)
  def size = joltage_levels.size
  def to_s ="{#{joltage_levels.join(",")}}"
  def inspect = to_s
end
