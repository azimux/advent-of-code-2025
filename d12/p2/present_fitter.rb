class PresentFitter
  class << self
    def can_fit?(region, present_counts)
      new(region, present_counts).can_fit?
    end
  end

  attr_accessor :region, :present_counts

  def initialize(region, present_counts)
    self.region = region
    self.present_counts = present_counts
  end

  def can_fit?
    if present_counts.values.all? { |i| i <= 0 }
      binding.pry
    end
    return false if region.width < 3
    return false if total_present_area > available_area

    present_counts.each_pair do |index, count|
      next if count.zero?

      present = PresentShape[index]

      present.each_variant do |present_variant|
        region.candidate_starting_points(present_variant) do |x, y|
          new_present_counts = present_counts.dup

          new_present_counts[index] = count - 1

          return true if new_present_counts.values.all?(&:zero?)

          new_region = region.dup

          new_region.add_present_shape_at(present_variant, x, y)
          new_region.trim!(new_present_counts)

          next if new_region.width < 3

          if PresentFitter.can_fit?(new_region, new_present_counts)
            return true
          end
        end
      end
    end

    false
  end

  def total_present_area
    sum = 0

    present_counts.each_pair do |index, count|
      sum += PresentShape[index].area * count
    end

    sum
  end

  def available_area
    region.available_area
  end
end
