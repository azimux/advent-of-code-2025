require "fileutils"
require_relative "network_path"

class CacheThread < Thread
  class << self
    def write(file, path, result)
      path.each_part do |path_part|
        file.write(Marshal.dump(path_part))
      end

      file.write(Marshal.dump(:path_end))
      file.write(Marshal.dump(result))
    end

    def read_path(file)
      path_array = []

      loop do
        path_part = Marshal.load(file)

        break if path_part == :path_end

        unless path_part.is_a?(Symbol)
          raise "wtf"
        end

        path_array << path_part
      end

      path_array.reverse.inject(nil) do |path, path_part_symbol|
        NetworkPath.new(path_part_symbol, path)
      end
    end

    def read_result(file)
      Marshal.load(file)
    end
  end

  attr_accessor :start_at,
                :end_at,
                :cache,
                :queue,
                :cache_file_name

  def initialize(inputs_file_name, cache, start_at:, end_at:)
    self.cache_file_name = "#{inputs_file_name}.#{start_at}_#{end_at}.cache"
    self.start_at = start_at
    self.end_at = end_at
    self.queue = Queue.new

    load_cache

    super { do_it }
  end

  def load_cache
    return @cache if @cache

    cache = {}

    if File.exist?(cache_file_name)
      FileUtils.cp cache_file_name, "#{cache_file_name}.bak"

      begin
        File.open(cache_file_name) do |f|
          until f.eof?
            path = self.class.read_path(f)
            count = self.class.read_result(f)
            cache[path] = count
          end
        end
      rescue EOFError
        warn "cache corrupted, dumping out good values"
        # rubocop:disable Style/FileOpen
        cache_file = File.open(cache_file_name, "w")
        # rubocop:enable Style/FileOpen

        cache.each_pair do |path, count|
          self.class.write(cache_file, path, count)
        end

        cache_file.close

        FileUtils.cp cache_file_name, "#{cache_file_name}.bak"
      end
    end

    @cache = cache
  end

  def do_it
    until queue.closed?
      path = queue.pop

      break if path == :stop

      count = queue.pop

      if path && count
        file = cache_file
        self.class.write(file, path, count)
        file.flush
      end
    end
  end

  def dirty! = queue << true
  def stop = queue << :stop

  def close!
    stop
    queue.close
  end

  def write_to_cache(path, count)
    queue << path
    queue << count
  end

  def cache_file
    return @cache_file if @cache_file

    if File.exist?(cache_file_name)
      FileUtils.mv(cache_file_name, "#{cache_file_name}.bak")
    end

    # rubocop:disable Style/FileOpen
    @cache_file = File.open(cache_file_name, "a")
    # rubocop:enable Style/FileOpen
  end
end
