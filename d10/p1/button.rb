require_relative 'light_panel'

class Button
  attr_accessor :lights_to_toggle, :light_panel_toggle_value

  def initialize(lights_to_toggle, light_count)
    self.lights_to_toggle = lights_to_toggle
    light_panel = []

    lights_to_toggle.each do |light_index|
      light_panel[light_index] = "#"
    end

    light_panel = light_panel[(0..light_count)]
    light_panel.reverse!
    light_panel.map! { it || "." }

    self.light_panel_toggle_value = LightPanel.new(light_panel.join)
  end

  def to_s
    s = light_panel_toggle_value.to_s

    button_wires = []

    s.chars.reverse.each.with_index do |char, index|
      button_wires << index if char == "#"
    end

    "(#{button_wires.join(",")})"
  end
end
