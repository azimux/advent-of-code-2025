module MinimumPushesCache
  @minimum_push_caches = {}
  @cache_writes = 0
  @cache_file_queue = nil

  class << self
    attr_accessor :cache_file_name

    def load_cache_from_file
      if cache_file_name
        if File.exist?(cache_file_name)
          FileUtils.cp cache_file_name, "#{cache_file_name}.bak"

          begin
            File.open(cache_file_name) do |f|
              until f.eof?
                # rubocop:disable Security/MarshalLoad
                max_allowed_pushes = Marshal.load(f)
                cache_key = Marshal.load(f)
                cache_value = Marshal.load(f)
                # rubocop:enable Security/MarshalLoad
                cache = @minimum_push_caches[max_allowed_pushes] ||= {}
                cache[cache_key] = cache_value
              end
            end
          rescue EOFError
            puts "cache corrupted, dumping out good values"
            @cache_file ||= File.open(cache_file_name, "w")

            @minimum_push_caches.each_pair do |max_allowed_pushes, cache|
              cache.each_pair do |key, value|
                write_cache_entry_to_disk(max_allowed_pushes, key, value)
              end
            end

            @cache_file.close
            remove_instance_variable(:@cache_file)

            FileUtils.cp cache_file_name, "#{cache_file_name}.bak"
          end
        end

        @cache_file ||= File.open(cache_file_name, "a")
        @cache_file_queue ||= Queue.new
        @cache_file_thread ||= cache_file_thread
      end

      if defined?(@sorted_keys)
        remove_instance_variable(:@sorted_keys)
      end
    end

    def cache_file_thread
      Thread.new do
        loop do
          max_allowed_pushes = @cache_file_queue.pop
          key = @cache_file_queue.pop
          value = @cache_file_queue.pop

          write_cache_entry_to_disk(max_allowed_pushes, key, value)

          @cache_file.flush
        end
      end
    end

    def close_cache_file
      @cache_file&.close
    end

    def minimum_pushes_cached(machine)
      max_allowed_pushes = machine.max_allowed_pushes
      cache_key = machine.cache_key

      cache = if @minimum_push_caches.key?(max_allowed_pushes)
                @minimum_push_caches[max_allowed_pushes]
              else
                if defined?(@sorted_keys)
                  remove_instance_variable(:@sorted_keys)
                end

                @minimum_push_caches[max_allowed_pushes] = {}
              end

      if cache.key?(cache_key)
        return cache[cache_key]
      else
        each_cache_in_order do |other_cap, other_cache|
          if other_cache.key?(cache_key)
            value = other_cache[cache_key]

            if !value.nil? || other_cap > max_allowed_pushes
              enqueue_write_cache_entry_to_disk(max_allowed_pushes, cache_key, value)
              return cache[cache_key] = value
            end
          end
        end
      end

      value = yield

      enqueue_write_cache_entry_to_disk(max_allowed_pushes, cache_key, value)

      cache[cache_key] = value
    end

    def each_cache_in_order
      caches = @minimum_push_caches

      cache_keys = @sorted_keys

      unless cache_keys
        cache_keys = caches.keys
        cache_keys.compact!
        cache_keys.sort!

        @sorted_keys = cache_keys
      end

      # TODO: memoize these sorted keys

      cache_keys.each do |cap|
        if caches.key?(cap)
          yield cap, caches[cap]
        end
      end

      if caches.key?(nil)
        yield nil, caches[nil]
      end
    end

    def enqueue_write_cache_entry_to_disk(cap, key, value)
      if @cache_file
        @cache_file_queue << cap
        @cache_file_queue << key
        @cache_file_queue << value
      end
    end

    def write_cache_entry_to_disk(cap, key, value)
      @cache_file.write(Marshal.dump(cap))
      @cache_file.write(Marshal.dump(key))
      @cache_file.write(Marshal.dump(value))
    end

    def cache_size
      @minimum_push_caches.values.map(&:size).sum
    end
  end
end
