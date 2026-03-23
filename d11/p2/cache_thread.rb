require "fileutils"

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
            node = read_node
            count = read_result

            cache[node] = count
          end
        end
      rescue EOFError
        warn "cache corrupted, dumping out good values"
        # rubocop:disable Style/FileOpen
        cache_file = File.open(cache_file_name, "w")
        # rubocop:enable Style/FileOpen

        cache.each_pair { |node, count| write(node, count) }
        cache_file.close
      ensure
        @cache_file = nil
      end
    end

    @cache = cache
  end

  def do_it
    until queue.closed?
      node = queue.pop

      break if node == :stop

      count = queue.pop

      if node && count
        write(node, count)
        flush
      end
    end
  end

  def stop = queue << :stop
  def flush = cache_file.flush

  def close!
    stop
    queue.close
  end

  def write_to_cache(node, count)
    queue << node
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

  def write(node, result)
    cache_file.write(Marshal.dump(node))
    cache_file.write(Marshal.dump(result))
  end

  def read_node
    node = Marshal.load(cache_file)

    unless node.is_a?(Symbol)
      raise "wtf"
    end

    node
  end

  def read_result = Marshal.load(cache_file)
end
