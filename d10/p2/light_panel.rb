class LightPanel
  attr_accessor :state, :light_count

  def initialize(state_string_or_light_count)
    if state_string_or_light_count.is_a?(String)
      self.light_count = state_string_or_light_count.size
      self.state = state_string_or_light_count.gsub(".", "0").gsub("#", "1").to_i(2)
    else
      self.light_count = state_string_or_light_count
      self.state = 0
    end
  end

  def size = light_count

  def to_s
    s = state.to_s(2)
    s = s.gsub("0", ".").gsub("1", "#")

    (light_count - s.size).times do
      s = ".#{s}"
    end

    s
  end

  def inspect = to_s
end
