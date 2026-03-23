require_relative "cache_thread"

class NetworkPathCounter
  attr_accessor :network,
                :start_at,
                :end_at,
                :cache,
                :cache_thread,
                :wait_on_cache,
                :exclude,
                :must_see,
                :cache_file_name

  def initialize(network, start_at:, end_at:, wait_on_cache: false, must_see: nil, exclude: nil)
    self.must_see = must_see == [] ? nil : must_see
    self.exclude = [*exclude] if exclude
    self.network = network
    self.start_at = start_at
    self.end_at = end_at
    self.wait_on_cache = wait_on_cache
  end

  def answer
    cache_file_name_parts = [inputs_file_name, start_at, end_at]

    if exclude
      cache_file_name_parts = [*cache_file_name_parts, *exclude]
    end

    if must_see
      cache_file_name_parts = [*cache_file_name_parts, "m", *must_see]
    end

    self.cache_file_name = [*cache_file_name_parts, "cache"].join(".")

    self.cache_thread = CacheThread.new(cache_file_name)
    self.cache = cache_thread.cache

    path_count_from(start_at, must_see: must_see.dup)
  ensure
    if wait_on_cache
      cache_thread.stop
    else
      cache_thread.close!
    end
  end

  def inputs_file_name = network.inputs_file_name

  private

  def cached(node)
    result = cache[node]

    if result
      puts "Cache hit on #{node}: #{result}"
    end

    unless result
      result = yield

      cache[node] = result

      cache_thread.write_to_cache(node, result)
    end

    result
  end

  def path_count_from(node, must_see:)
    return 0 if exclude&.include?(node)

    cached(node) do
      if must_see&.include?(node)
        must_see = if must_see.size == 1
                     nil
                   else
                     must_see.reject { it == node }
                   end
      end

      destinations = network[node] || []

      destinations.map do |destination|
        if destination == end_at
          if must_see.nil?
            puts "found a path!!"
            1
          else
            0
          end
        else
          path_count_from(destination, must_see:)
        end
      end.sum
    end
  end
end
