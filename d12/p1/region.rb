class Region
  attr_accessor :height, :width, :present_counts

  def initialize(height:, width:, present_counts:)
    self.height = height
    self.width = width
    self.present_counts = present_counts
  end
end
