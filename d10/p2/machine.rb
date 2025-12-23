require_relative "array"

class Machine
  attr_accessor :target_joltages, :buttons

  def initialize(target_joltages, buttons)
    self.target_joltages = target_joltages
    self.buttons = buttons
  end

  def minimum_pushes_required_old
    (1..(buttons.size * joltages_size)).each do |button_count|
      puts "#{target_joltages} button count: #{button_count}"
      buttons.choose_allowing_repetition(button_count).each do |buttons_to_push|
        joltages = Joltages.new([0] * joltages_size)

        buttons_to_push.each do |button|
          button.push(joltages)
          break if joltages.any_over?(target_joltages)
        end

        if joltages == target_joltages
          return button_count
        end
      end
    end

    binding.pry

    raise "wtf"
  end

  # TODO: build these one at a time and yield them instead of building them all
  # upfront
  def minimum_pushes_required
    (1..(buttons.size * joltages_size)).each do |button_count|
      puts "#{target_joltages} button count: #{button_count}"
      buttons.choose_allowing_repetition(button_count).each do |buttons_to_push|
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

  def joltages_size = target_joltages.size
  def to_s = "#{buttons.map(&:to_s).join(" ")} #{target_joltages}"
end
