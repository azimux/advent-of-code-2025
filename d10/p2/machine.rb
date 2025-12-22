require_relative "array"

class Machine
  attr_accessor :target_joltages, :buttons

  def initialize(target_joltages, buttons)
    self.target_joltages = target_joltages
    self.buttons = buttons
  end

  def minimum_pushes_required
    (1..buttons.size).each do |button_count|
      buttons.choose(button_count).each do |buttons_to_push|
        joltages = Joltages.new([0] * joltages_size)

        if target_joltages == Joltages.new([3, 5, 4, 7])
          binding.pry
        end
        buttons_to_push.each do |button|
          button.push(joltages)
        end

        if joltages == target_joltages
          return button_count
        end
      end
    end

    binding.pry

    raise "wtf"
  end

  def joltages_size = target_joltages.size
  def to_s = "#{buttons.map(&:to_s).join(" ")} #{target_joltages}"
end
