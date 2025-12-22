require_relative 'light_panel'

class Button
  attr_accessor :lights_to_toggle, :light_panel

  def initialize(lights_to_toggle, light_count)
    self.lights_to_toggle = lights_to_toggle
    light_panel_string = Array.new(light_count)

    lights_to_toggle.each do |light_index|
      light_panel_string[light_index] = "#"
    end

    light_panel_string = light_panel_string[(0..light_count)]
    light_panel_string.map! { it || "." }
    light_panel_string = light_panel_string.join

    self.light_panel = LightPanel.new(light_panel_string)
  end

  def push(light_panel)
    light_panel.state ^= light_panel_toggle_value
  end

  def light_panel_toggle_value
    light_panel.state
  end

  def to_s
    s = light_panel.to_s

    button_wires = []

    s.chars.each.with_index do |char, index|
      button_wires << index if char == "#"
    end

    "(#{button_wires.join(",")})"
  end

  def inspect = to_s
end
