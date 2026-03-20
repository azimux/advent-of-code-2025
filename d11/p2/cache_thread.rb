require "fileutils"
require_relative "network_path"

class CacheThread < Thread
  attr_accessor :cache,
                :queue,
                :cache_file_name

  def initialize(cache_file_name)
    self.cache_file_name = cache_file_name
    self.queue = Queue.new

    load_cache

    super { do_it }
  end

  def load_cache
    return @cache if @cache

    cache = {}

    if File.exist?(cache_file_name)
      begin
        File.open(cache_file_name, "rb") do |f|
          @cache_file = f

          until f.eof?
            path = read_path
            count = read_result

            cache[path] = count
          end
        end
      rescue EOFError
        warn "cache corrupted, dumping out good values"
        # rubocop:disable Style/FileOpen
        cache_file = File.open(cache_file_name, "w")
        # rubocop:enable Style/FileOpen

        cache.each_pair do |path, count|
          write(path, count)
        end

        cache_file.close
      ensure
        @cache_file = nil
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
        write(path, count)
        flush
      end
    end
  end

  def dirty! = queue << true
  def stop = queue << :stop
  def flush = cache_file.flush

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
      FileUtils.cp cache_file_name, "#{cache_file_name}.bak"
    end

    # rubocop:disable Style/FileOpen
    @cache_file = File.open(cache_file_name, "ab")
    # rubocop:enable Style/FileOpen
  end

  def write(path, result)
    path.each_part do |path_part|
      cache_file.write(Marshal.dump(path_part))
    end

    cache_file.write(Marshal.dump(:path_end))
    cache_file.write(Marshal.dump(result))
  end

  def read_path
    path_array = []

    loop do
      path_part = Marshal.load(cache_file)

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

  def read_result = Marshal.load(cache_file)
end
