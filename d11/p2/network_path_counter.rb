require_relative "cache_thread"

class NetworkPathCounter
  attr_accessor :network,
                :start_at,
                :end_at,
                :seen,
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
    self.seen = Set.new

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

    path_count_from(start_at, path: nil, must_see: must_see.dup)
  ensure
    self.seen = nil

    if wait_on_cache
      cache_thread.stop
    else
      cache_thread.close!
    end
  end

  def inputs_file_name = network.inputs_file_name

  private

  def cached(path)
    result = cache[path]

    if result
      puts "Cache hit on #{path}: #{result}"
    end

    unless result
      result = yield

      cache[path] = result

      cache_thread.write_to_cache(path, result)
    end

    result
  end

  def path_count_from(node, path:, must_see:)
    return 0 if exclude&.include?(node)

    path = NetworkPath.new(node, path)

    if seen.include?(path)
      puts "cycle found!!!"
      return 0
    end

    seen << path

    cached(path) do
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
          path_count_from(destination, path:, must_see:)
        end
      end.sum
    end
  end
end
