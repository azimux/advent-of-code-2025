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
                :cache_file_name

  def initialize(network, start_at:, end_at:, wait_on_cache: false, exclude: nil)
    self.exclude = exclude
    self.network = network
    self.start_at = start_at
    self.end_at = end_at
    self.wait_on_cache = wait_on_cache
  end

  def answer
    self.seen = Set.new

    self.cache_file_name = [inputs_file_name, start_at, end_at, *exclude, "cache"].join(".")

    self.cache_thread = CacheThread.new(cache_file_name)
    self.cache = cache_thread.cache

    path_count_from(start_at, seen_fft: false, seen_dac: false, path: nil)
  ensure
    self.seen = nil

    if wait_on_cache
      cache_thread.stop
    else
      cache_thread.close!
    end
  end

  def inputs_file_name = network.inputs_file_name
  def join = cache_thread.join

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

  def path_count_from(node, seen_fft:, seen_dac:, path:)
    return 0 if exclude && exclude == node

    path = NetworkPath.new(node, path)

    return 0 if seen.include?(path)

    seen << path

    cached(path) do
      case node
      when :fft
        seen_fft = true
      when :dac
        seen_dac = true
      end

      destinations = network[node]

      destinations.map do |destination|
        if destination == end_at
          if seen_fft && seen_dac
            puts "found a path!!"
            1
          else
            0
          end
        else
          path_count_from(destination, seen_fft:, seen_dac:, path:)
        end
      end.sum
    end
  end
end
