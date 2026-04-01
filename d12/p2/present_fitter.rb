class PresentFitter
  attr_accessor :present_shapes, :region, :present_counts

  def initialize(present_shapes:, region:, present_counts:)
    self.present_shapes = present_shapes
    self.region = region
    self.present_counts = present_counts
  end

  def can_fill?
  end
end
