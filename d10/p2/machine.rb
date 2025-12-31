require_relative "array"

class Machine
  class << self
    def minimum_pushes_cached(machine)
      @minimum_pushes_cache ||= {}

      if @minimum_pushes_cache.key?(machine)
        @minimum_pushes_cache[machine]
      else
        @minimum_pushes_cache[machine] = yield
      end
    end

    def cache_size
      @minimum_pushes_cache&.size || 0
    end
  end

  attr_accessor :joltages, :buttons, :original_to_s

  def initialize(joltages, buttons, top_level = true)
    self.joltages = joltages
    self.buttons = buttons

    self.original_to_s = to_s if top_level

    normalize!
  end

  def done? = joltages.done?
  def cannot_have_a_solution? = buttons.empty?

  def crude_max_pushes
    return @crude_max_pushes if defined?(@crude_max_pushes)

    min_joltage_size = buttons.map(&:joltages_size).min

    joltages_sum = joltages.sum

    dividend = joltages_sum / min_joltage_size

    @crude_max_pushes = if joltages_sum % min_joltage_size == 0
                          dividend
                        else
                          dividend + 1
                        end
  end

  def crude_min_pushes
    max_joltage_size = buttons.map(&:joltages_size).max

    joltages_sum = joltages.sum

    joltages_sum / max_joltage_size
  end

  def minimum_pushes_required(top_level = true)
    if top_level
      # puts "#{Time.now}: starting #{self}"
      $i ||= 0
      $i += 1
      $previous_time ||= Time.now
      $current_time = Time.now
      span = $current_time - $previous_time
      $total_time ||= 0
      $total_time += span
      puts "#{$current_time} #{span.to_i}s ##{$i} #{$total_time / $i} s/m cache: #{self.class.cache_size}"
      $previous_time = $current_time
    end

    minimum_pushes_cached do
      minimum_pushes_required_without_cache(top_level)
    end
  end

  def minimum_pushes_required_without_cache(top_level = true)
    target_button = buttons.first

    if target_button.nil?
      if done?
        return 0
      else
        # binding.pry if top_level
        return nil
      end
    end

    target_joltage_index = minimum_nonzero_joltage_index(target_button)

    if target_joltage_index.nil?
      if done?
        return 0
      else
        # binding.pry if top_level
        return nil
      end
    end

    target_joltage = joltages[target_joltage_index]

    worst_case_pushes = crude_max_pushes - target_joltage

    relevant_buttons = buttons.select { |button| button.include?(target_joltage_index) }
    relevant_buttons.reject! do |button|
      button.joltages_to_increment.any? do |joltage_index|
        joltages[joltage_index].zero?
      end
    end

    minimum_submachine_pushes = nil

    # binding.pry

    relevant_buttons.button_presses(target_joltage) do |button_presses|
      if top_level
        # puts "#{Time.now}: #{self} creating a submachine for #{worst_case_pushes}"
      end

      new_joltages = joltages.dup
      button_presses.each { |button_press| button_press.push(new_joltages) }

      unless new_joltages.any?(&:negative?)
        if new_joltages.done?
          return target_joltage * multiplier
        end

        new_buttons = buttons - relevant_buttons

        if new_buttons.empty?
          if done?
            raise "wtf"
            binding.pry
          end
          next
        end

        submachine = Machine.new(new_joltages, new_buttons, false)

        if submachine.cannot_have_a_solution?
          # if done?
          #   raise "wtf"
          #   binding.pry
          # end
          next
        end

        if submachine.crude_min_pushes > worst_case_pushes
          if done?
            raise "not expecting done!"
            binding.pry
          end
          next
        end

        # submachine.update_multiplier!
        #
        # if submachine.multiplier > 1
        #   min_pushes = submachine.minimum_pushes_required(false)
        #
        #   if min_pushes
        #     min_pushes *= submachine.multiplier
        #     return target_joltage + min_pushes
        #   else
        #     # There was no solution for the multiplier submachine so revert
        #     # to the real submachine and continue looking for a solution
        #     submachine = Machine.new(new_joltages, new_buttons, false)
        #   end
        # end

        min_pushes = submachine.minimum_pushes_required(false)

        if min_pushes
          return (target_joltage + min_pushes) * multiplier
        end
      end
    end

    if minimum_submachine_pushes.nil?
      binding.pry if top_level
    else
      (target_joltage + minimum_submachine_pushes) * multiplier
    end
  end

  def minimum_pushes_cached(&)
    self.class.minimum_pushes_cached(self, &)
  end

  def button_with_most_joltage_indices
    buttons.max_by do |button|
      button.joltages_to_increment.count do |joltage_index|
        joltages[joltage_index].positive?
      end
    end
  end

  def minimum_nonzero_joltage_index(button)
    joltages_to_increment = button.joltages_to_increment

    min_index = nil
    min_joltage = nil

    joltages_to_increment.each do |joltage_index|
      value = joltages[joltage_index]

      if value.positive? && (min_joltage.nil? || value < min_joltage)
        min_joltage = value
        min_index = joltage_index
      end
    end

    min_index
  end

  def multiplier
    @multiplier || 1
  end

  attr_writer :multiplier

  def update_multiplier!
    gcd = joltages.gcd

    if gcd
      self.multiplier *= gcd
      self.joltages /= gcd

      # binding.pry
      if instance_variable_defined?(:@crude_max_pushes)
        # binding.pry
        remove_instance_variable(:@crude_max_pushes)
      end
    end
  end

  def joltages_size = joltages.size
  def joltage_levels = joltages.joltage_levels

  def to_s
    s = "#{buttons.map(&:to_s).join(" ")} #{joltages} cache size: #{self.class.cache_size}"

    if multiplier > 1
      s += " x#{multiplier}"
    end

    if original_to_s
      "#{s} originally: #{original_to_s}"
    else
      s
    end
  end

  # Normalize to allow for more cache hits
  def normalize!
    remove_all_zero_joltages!
    update_multiplier!
    order_joltages!
    order_buttons!
  end

  def remove_all_zero_joltages!
    indices_to_remove = []

    joltages.each.with_index do |joltage_level, index|
      if joltage_level.zero?
        indices_to_remove << index
      end
    end

    return if indices_to_remove.empty?

    updated_joltages = []

    joltages.each.with_index do |joltage_level, index|
      unless indices_to_remove.include?(index)
        updated_joltages << joltage_level
      end
    end

    self.joltages = Joltages.new(updated_joltages)

    indices_to_remove.reverse!

    indices_to_remove.each do |index|
      buttons.map! do |button|
        new_joltages = button.joltages_to_increment.map do |joltage_index|
          if joltage_index > index
            joltage_index - 1
          elsif joltage_index < index
            joltage_index
          end
        end

        new_joltages.compact!

        next if new_joltages.empty?

        Button.new(new_joltages)
      end

      buttons.compact!
      buttons.uniq!
    end
  end

  def order_joltages!
    joltage_index_map = joltage_levels.map.with_index do |level, index|
      [level, index]
    end

    sorted_joltage_index_map = joltage_index_map.sort

    return if sorted_joltage_index_map == joltage_index_map

    self.joltages = Joltages.new(sorted_joltage_index_map.map(&:first))

    joltage_index_map = sorted_joltage_index_map.map(&:last).map.with_index do |old_index, new_index|
      [old_index, new_index]
    end.to_h

    buttons.map! do |button|
      new_joltage_indices = button.joltages_to_increment.map do |old_joltage_index|
        joltage_index_map[old_joltage_index]
      end

      Button.new(new_joltage_indices)
    end
  end

  def order_buttons!
    buttons.sort_by!(&:joltages_size)
    buttons.reverse!
  end

  def hash
    # rubocop:disable Security/CompoundHash
    buttons.hash ^ joltages.hash
    # rubocop:enable Security/CompoundHash
  end

  def ==(other)
    other.is_a?(Machine) && joltages == other.joltages && buttons == other.buttons
  end

  def eql?(other) = self == other
end
