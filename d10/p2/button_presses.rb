class ButtonPresses
  attr_accessor :button, :press_count

  def initialize(button, press_count)
    self.button = button
    self.press_count = press_count

    raise "wtf" if press_count.zero?
  end

  def joltages_size = button.joltages_size * press_count

  def push(joltages)
    button.joltages_to_increment.each { joltages.dec(it, press_count) }
  end
end
