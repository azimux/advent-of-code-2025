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
    $calls ||= 0
    $calls += 1

    if $calls % 1000 == 0
      puts "#{$calls} calls"
      puts present_counts.inspect
      puts region
      puts
    end

    if present_counts.values.all? { |i| i <= 0 }
      binding.pry
    end
    return false if region.width < 3 || region.height < 3
    return false if total_present_area > available_area

    # This hack doesn't seem to speed us up since we don't hit the breakpoint in the
    # test data, but maybe worth trying against the real data
    # empty_height = (region.height - region.non_empty_row_count)
    # fittable_three_by_three_presents_count = (empty_height / 3) * (region.width / 3)
    #
    # if fittable_three_by_three_presents_count >= present_counts.values.sum
    #   binding.pry
    #   return true
    # end

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

          next if new_region.width < 3 || new_region.height < 3

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
