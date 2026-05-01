require "fileutils"

class CacheThread < Thread
  attr_accessor :cache, :queue, :cache_file_name

  def initialize(cache:, cache_file_name:)
    self.cache = cache
    self.cache_file_name = cache_file_name
    self.queue = Queue.new

    load_cache

    super { do_it }
  end

  def load_cache
    if File.exist?(cache_file_name)
      begin
        File.open(cache_file_name, "rb") do |f|
          @cache_file = f

          until f.eof?
            region_spaces = read
            remaining_presents = read
            can_fit = read

            cache.add_to_cache(region_spaces, remaining_presents, can_fit)
          end
        end
      rescue EOFError
        warn "cache corrupted, dumping out good values"
        # rubocop:disable Style/FileOpen
        @cache_file = File.open(cache_file_name, "w")
        # rubocop:enable Style/FileOpen

        cache.each_triple do |region_spaces, remaining_presents, can_fit|
          write(region_spaces, remaining_presents, can_fit)
        end

        cache.each_pair { |node, count| write(node, count) }
        @cache_file.close
      ensure
        @cache_file = nil
      end
    end

    @cache = cache
  end

  def do_it
    until queue.closed?
      region_spaces = queue.pop

      break if region_spaces == :stop

      present_counts = queue.pop
      can_fit = queue.pop

      write(region_spaces, present_counts, can_fit)
      flush
    end
  end

  def stop
    queue << :stop
    join
  end

  def flush = cache_file.flush

  def close!
    stop
    queue.close
  end

  def write_to_cache(region_spaces, remaining_presents, can_fit)
    queue << region_spaces
    queue << remaining_presents
    queue << can_fit
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

  def write(region_spaces, remaining_presents, can_fit)
    cache_file.write(Marshal.dump(region_spaces))
    cache_file.write(Marshal.dump(remaining_presents))
    cache_file.write(Marshal.dump(can_fit))
  end

  def read = Marshal.load(cache_file)
end
