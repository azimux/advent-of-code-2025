class Region
  attr_accessor :height, :width, :present_counts, :spaces

  def initialize(height:, width:, present_counts:)
    self.height = height
    self.width = width
    self.present_counts = present_counts

    self.spaces = Array.new(width) { Array.new(height, false) }
  end
  end
end
