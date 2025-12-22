require_relative "array"

class Machine
  attr_accessor :light_panel, :buttons

  def initialize(light_panel, buttons)
    self.light_panel = light_panel
    self.buttons = buttons
  end

  def minimum_pushes_required
    (1..buttons.size).each do |button_count|
      buttons.choose(button_count).each do |buttons_to_push|
        lp = LightPanel.new(light_count)

        buttons_to_push.each do |button|
          button.push(lp)
        end

        if lp.state == light_panel.state
          return button_count
        end
      end
    end

    raise "wtf"
  end

  def light_count = light_panel.size
  def to_s = "#{light_panel} #{buttons.map(&:to_s).join(" ")}"
end
