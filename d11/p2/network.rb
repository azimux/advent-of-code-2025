require_relative "cache_thread"

class Network
  attr_accessor :graph, :start_at, :seen, :cache, :inputs_file, :cache_thread, :wait_on_cache

  def initialize(inputs_file, start_at, wait_on_cache: false)
    self.inputs_file = inputs_file
    self.start_at = start_at
    self.wait_on_cache = wait_on_cache

    inputs = File.read(inputs_file)

    lines = inputs.split("\n")

    self.graph = {}

    lines.each do |line|
      if line =~ /(\w+):(.*)/
        source = $1
        destination = $2.scan(/\w+/)

        graph[source.to_sym] = destination.map(&:to_sym)
      else
        raise "Unexpected line #{line}"
      end
    end
  end

  def answer
    self.seen = Set.new
    self.cache = CacheThread.load_cache(inputs_file)
    self.cache_thread = CacheThread.new(inputs_file, cache)

    path_count_from(start_at, seen_fft: false, seen_dac: false, path: nil)
  ensure
    self.seen = nil

    if wait_on_cache
      cache_thread.stop
    else
      cache_thread.close!
    end
  end

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

      destinations = graph[node]

      destinations.map do |destination|
        if destination == :out
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
