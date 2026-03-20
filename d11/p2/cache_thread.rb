require "fileutils"
require_relative "network_path"

class CacheThread < Thread
  class << self
    def load_cache(inputs_file_name)
      cache_file_name = self.cache_file_name(inputs_file_name)
      cache = {}

      if File.exist?(cache_file_name)
        FileUtils.cp cache_file_name, "#{cache_file_name}.bak"

        begin
          File.open(cache_file_name) do |f|
            until f.eof?
              path = read_path(f)
              count = read_result(f)
              cache[path] = count
            end
          end
        rescue EOFError
          warn "cache corrupted, dumping out good values"
          # rubocop:disable Style/FileOpen
          cache_file = File.open(cache_file_name, "w")
          # rubocop:enable Style/FileOpen

          cache.each_pair do |path, count|
            write(cache_file, path, count)
          end

          cache_file.close

          FileUtils.cp cache_file_name, "#{cache_file_name}.bak"
        end
      end

      cache
    end

    def cache_file_name(inputs_file_name)
      "#{inputs_file_name}.cache"
    end

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

  attr_accessor :inputs_file_name, :cache, :queue

  def initialize(inputs_file_name, cache)
    self.inputs_file_name = inputs_file_name
    self.queue = Queue.new

    super { do_it }
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

    cache_file_name = self.class.cache_file_name(inputs_file_name)

    if File.exist?(cache_file_name)
      FileUtils.mv(cache_file_name, "#{cache_file_name}.bak")
    end

    # rubocop:disable Style/FileOpen
    @cache_file = File.open(cache_file_name, "a")
    # rubocop:enable Style/FileOpen
  end

  def cache_file_name
    @cache_file_name ||= self.class.cache_file_name(inputs_file_name)
  end
end
