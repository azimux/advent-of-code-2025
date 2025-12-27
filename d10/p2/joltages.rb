class Joltages
  attr_accessor :joltage_levels

  def initialize(joltage_levels)
    self.joltage_levels = joltage_levels
  end

  def ==(other)
    other.is_a?(Joltages) && joltage_levels == other.joltage_levels
  end

  def hash = joltage_levels.hash
  def eql?(other) = self == other

  def dec(i, amount = 1) = joltage_levels[i] -= amount
  def dup = Joltages.new(joltage_levels.dup)
  def any?(&) = joltage_levels.any?(&)
  def all?(&) = joltage_levels.all?(&)
  def sum = joltage_levels.sum
  def done? = joltage_levels.all?(&:zero?)
  def gcd = joltage_levels.gcd_ish
  def /(other) = Joltages.new(joltage_levels.map { it / other })

  def any_over?(target)
    target_levels = target.joltage_levels

    joltage_levels.each.with_index.any? do |level, index|
      level > target_levels[index]
    end
  end

  def [](index) = joltage_levels[index]

  def each(&) = joltage_levels.each(&)
  def size = joltage_levels.size
  def to_s = "{#{joltage_levels.join(",")}}"
  def inspect = to_s
end
