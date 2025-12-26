require_relative "array"

class Machine
  class << self
    def seen?(joltages, button_presses)
      seen.include?([joltages, button_presses])
    end

    def mark_seen(joltages, button_presses)
      seen << [joltages, button_presses]
    end

    def cached(joltages, button_presses) = seen[[joltages, button_presses]]
    def reset_cache! = seen.clear

    private

    def seen
      @seen ||= Set.new
    end
  end

  attr_accessor :joltages, :buttons

  def initialize(joltages, buttons)
    self.joltages = joltages
    self.buttons = buttons
  end

  # Normalize to allow for more cache hits
  def normalize!
    # TODO:
    # remove all zero values from joltages
    #   #NOTE: maybe not necessary because we have no buttons with indices to zero joltage values
    #   not necessary with current algorithm: remove those indices from all buttons
    # order joltages from lowest to highest
    #   which means re-ordering button joltage indices to match, and in case of tie, use index value
  end

  def done? = joltages.done?

  def crude_max_pushes
    return @crude_max_pushes if defined?(@crude_max_pushes)

    min_joltage_size = buttons.map(&:joltages_size).min

    binding.pry if min_joltage_size.nil?

    joltages_sum = joltages.sum

    dividend = joltages_sum / min_joltage_size

    @crude_max_pushes = if joltages_sum % min_joltage_size == 0
                          dividend
                        else
                          dividend + 1
                        end
  end

  def minimum_pushes_required(top_level = true)
    self.class.reset_cache! if top_level

    target_button = buttons.first
    if target_button.nil?
      return done? ? 0 : nil
    end

    target_joltage_index = minimum_nonzero_joltage_index(target_button)
    if target_joltage_index.nil?
      return done? ? 0 : nil
    end

    target_joltage = joltages[target_joltage_index]

    worse_case_pushes = crude_max_pushes - target_joltage

    relevant_buttons = buttons.select { |button| button.include?(target_joltage_index) }
    relevant_buttons.reject! do |button|
      button.joltages_to_increment.any? do |joltage_index|
        joltages[joltage_index].zero?
      end
    end

    minimum_submachine_pushes = nil

    relevant_buttons.button_presses(target_joltage) do |button_presses|
      if top_level
        puts "#{Time.now}: #{self} creating a submachine for #{button_presses.sum(&:joltages_size)}"
      end

      if seen?(joltages, button_presses)
        raise "yay!"
        # TODO: need to actually cache these values!
        return cached(joltages, button_presses)
      end

      mark_seen(joltages, button_presses)

      new_joltages = joltages.dup
      button_presses.each { |button_press| button_press.push(new_joltages) }

      unless new_joltages.any?(&:negative?)
        if new_joltages.done?
          return target_joltage
        end

        new_buttons = buttons - relevant_buttons
        if new_buttons.empty?
          next
        end

        submachine = Machine.new(new_joltages, buttons - relevant_buttons)

        if submachine.crude_max_pushes > worse_case_pushes
          raise "skipping due to worst case pushes!!!"
          next
        end

        min_pushes = submachine.minimum_pushes_required(false)

        if min_pushes
          return target_joltage + min_pushes
        end
      end
    end

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
    end

    min_index
  end

  def joltages_size = joltages.size
  def to_s = "#{buttons.map(&:to_s).join(" ")} #{joltages}"

  def seen?(joltages, button_presses) = self.class.seen?(joltages, button_presses)
  def mark_seen(joltages, button_presses) = self.class.mark_seen(joltages, button_presses)
  def cached(joltages, button_presses) = self.class.cached(joltages, button_presses)
end
