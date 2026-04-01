class PresentFitter
  attr_accessor :region, :present_counts

  def initialize(region:, present_counts:)
    self.region = region
    self.present_counts = present_counts
  end

  def can_fill?
  end
end
