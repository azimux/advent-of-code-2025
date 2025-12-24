require_relative "array"

# potential algorithms...
# 1)
#   a. find button with most joltage indices in it
#   b. find joltage index with the lowest target value
#   c. build collection of possible button presses to get to that target value
#   d. build a new machine for each possible value but without any of the
#      no-longer pressable buttons and without the joltage we already met.
#   e. go back to a.

class Machine
  attr_accessor :target_joltages, :buttons

  def initialize(target_joltages, buttons)
    self.target_joltages = target_joltages
    self.buttons = buttons
  end

  def minimum_pushes_required
    # 1. build up all sets of button pushes for buttons containing first joltage
    # that give exactly the first joltage
    # 2. delete all of those buttons
    # 3. repeat step 1 combining existing sets with button pushes from other buttons
    #    to build new set containing all button pushes that satisfy joltage1 and joltage2
    (1..(buttons.size * joltages_size)).each do |button_count|
      puts "#{Time.now}: #{target_joltages} button count: #{button_count}"

      possible_button_combinations(button_count) do |buttons_to_push|
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

  def possible_button_combinations(button_count, &)
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

    buttons_to_choose_from.choose(button_count, &)
  end

  def joltages_size = target_joltages.size
  def to_s = "#{buttons.map(&:to_s).join(" ")} #{target_joltages}"
end
