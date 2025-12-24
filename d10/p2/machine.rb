require_relative "array"

class Machine
  attr_accessor :joltages, :buttons

  def initialize(joltages, buttons)
    self.joltages = joltages
    self.buttons = buttons
  end

  def minimum_pushes_required
    binding.pry

    target_button = button_with_most_joltage_indices
    return 0 if target_button.nil?

    target_joltage_index = minimum_nonzero_joltage_index(target_button)
    return 0 if target_joltage_index.nil?

    binding.pry

    target_joltage = joltages[target_joltage_index]

    relevant_buttons = buttons.select { |button| button.include?(target_joltage_index) }
    relevant_buttons.reject! do |button|
      button.joltages_to_increment.any? do |joltage_index|
        joltages[joltage_index].zero?
      end
    end

    minimum_submachine_pushes = nil

    relevant_buttons.choose_allowing_repetition(target_joltage) do |buttons_to_push|
      new_joltages = joltages.dup
      buttons_to_push.each { |button| button.push(new_joltages) }

      unless new_joltages.any?(&:negative?)
        submachine = Machine.new(new_joltages, buttons - relevant_buttons)
        min_pushes = submachine.minimum_pushes_required

        next unless min_pushes

        if minimum_submachine_pushes.nil? || min_pushes < minimum_submachine_pushes
          minimum_submachine_pushes = min_pushes
        end
      end
    end

    binding.pry

    unless minimum_submachine_pushes.nil?
      target_joltage + minimum_submachine_pushes
    end
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

    (0...joltages_to_increment.size).each do |i|
      joltage_index = joltages_to_increment[i]
      value = joltages[joltage_index]

      if value.positive? && (min_joltage.nil? || value < min_joltage)
        min_joltage = value
        min_index = joltage_index
      end
    end.tap do
      binding.pry if it.nil?
    end

    min_index
  end

  def joltages_size = joltages.size
  def to_s = "#{buttons.map(&:to_s).join(" ")} #{joltages}"
end
