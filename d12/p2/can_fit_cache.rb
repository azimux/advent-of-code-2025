require_relative "cache_thread"

class CanFitCache
  attr_accessor :cache_thread

  def initialize(cache_file_name)
    @top_level = {}
    self.cache_thread = CacheThread.new(cache: self, cache_file_name:)
  end

  def cached(region_spaces, present_counts)
    lower_level = @top_level[region_spaces] ||= {}

    if lower_level.key?(present_counts)
      lower_level[present_counts]
    else
      can_fit = yield

      lower_level[present_counts] = can_fit
      cache_thread.write_to_cache(region_spaces, present_counts, can_fit)

      can_fit
    end
  end

  def add_to_cache(region_spaces, present_counts, can_fit)
    lower_level = @top_level[region_spaces] ||= {}

    lower_level[present_counts] = can_fit
  end

  def each_triple
    @top_level.each_pair do |region_spaces, present_counts_to_can_fit|
      present_counts_to_can_fit.each_pair do |present_counts, can_fit|
        yield region_spaces, present_counts, can_fit
      end
    end
  end

  def stop = cache_thread.stop
end
