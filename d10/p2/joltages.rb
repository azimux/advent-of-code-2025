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

  def gcd
    joltage_levels = self.joltage_levels

    best_gcd = joltage_levels.gcd_ish
    gcd = best_gcd

    while gcd
      joltage_levels = joltage_levels.map { |i| i / gcd }

      gcd = joltage_levels.gcd_ish

      if gcd
        best_gcd *= gcd
      else
        return best_gcd
      end
    end

    best_gcd
  end

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
  def min = joltage_levels.min

  def index_of_min
    min_index = 0
    min_joltage = joltage_levels.first

    1.upto(joltage_levels.size - 1) do |i|
      level = joltage_levels[i]
      if level < min_joltage
        min_joltage = level
        min_index = i
      end
    end

    min_index
  end
end
