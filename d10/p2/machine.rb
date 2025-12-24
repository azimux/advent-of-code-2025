require_relative "array"

class Machine
  attr_accessor :target_joltages, :buttons

  def initialize(target_joltages, buttons)
    self.target_joltages = target_joltages
    self.buttons = buttons
  end

  def minimum_pushes_required
    (1..(buttons.size * joltages_size)).each do |button_count|
      puts "#{date}: #{target_joltages} button count: #{button_count}"

      possible_button_combinations(button_count).each do |buttons_to_push|
        works = true

        target_joltages.each.with_index do |joltage, index|
          unless buttons_to_push.count { |b| b.include?(index) } == joltage
            works = false
            break
          end
        end

        return buttons_to_push.size if works
      end
    end

    binding.pry

    raise "wtf"
  end

  def possible_button_combinations(button_count)
    buttons_to_choose_from = []

    buttons.each do |button|
      joltages = Joltages.new(Array.new(target_joltages.size, 0))
      count = 0

      loop do
        button.push(joltages)

        break if joltages.any_over?(target_joltages)

        buttons_to_choose_from << button
        count += 1

        break if count >= button_count
      end
    end

    buttons_to_choose_from.choose(button_count)
  end

  def joltages_size = target_joltages.size
  def to_s = "#{buttons.map(&:to_s).join(" ")} #{target_joltages}"
end
