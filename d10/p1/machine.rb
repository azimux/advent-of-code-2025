class Machine
  attr_accessor :light_panel, :buttons

  def initialize(light_panel, buttons)
    self.light_panel = light_panel
    self.buttons = buttons
  end

  def to_s = "#{light_panel} #{buttons.map(&:to_s).join(" ")}"
end
