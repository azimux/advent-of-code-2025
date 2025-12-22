class LightPanel
  attr_accessor :state, :light_count

  def initialize(state_string)
    self.light_count = state_string.size
    self.state = state_string.gsub(".", "0").gsub("#", "1").to_i(2)
  end

  def size =light_count

  def to_s
    s = state.to_s(2)
    s = s.gsub("0", ".").gsub("1", "#")

    (light_count - s.size).times do
      s = ".#{s}"
    end

    s
  end
end
