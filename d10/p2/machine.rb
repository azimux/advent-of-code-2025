require "fileutils"

require_relative "array"

class Machine
  @minimum_pushes_cache = {}
  @cache_writes = 0
  @cache_file_queue = nil

  class << self
    def load_cache_from_file
      if MachineParser.last_parsed_filename
        cache_file_name = "#{MachineParser.last_parsed_filename.gsub(/\.txt$/, "")}.cache"

        if File.exist?(cache_file_name)
          FileUtils.cp cache_file_name, "#{cache_file_name}.bak"

          begin
            File.open(cache_file_name) do |f|
              until f.eof?
                # rubocop:disable Security/MarshalLoad
                cache_key = Marshal.load(f)
                cache_value = Marshal.load(f)
                # rubocop:enable Security/MarshalLoad
                @minimum_pushes_cache[cache_key] = cache_value
              end
            end
          rescue EOFError
            puts "cache corrupted, dumping out good values"
            cache_file = File.open(cache_file_name, "w")

            @minimum_pushes_cache.each_pair do |key, value|
              cache_file.write(Marshal.dump(key))
              cache_file.write(Marshal.dump(value))
            end

            @cache_file = cache_file
          end
        end

        @cache_file ||= File.open(cache_file_name, "a")
        @cache_file_queue ||= Queue.new
        @cache_file_thread ||= cache_file_thread
      end
    end

    def cache_file_thread
      Thread.new do
        loop do
          key = @cache_file_queue.pop
          value = @cache_file_queue.pop

          @cache_file.write(Marshal.dump(key))
          @cache_file.write(Marshal.dump(value))
          @cache_file.flush
        end
      end
    end

    def close_cache_file
      @cache_file&.close
    end

    def minimum_pushes_cached(cache_key)
      if @minimum_pushes_cache.key?(cache_key)
        @minimum_pushes_cache[cache_key]
      else
        value = yield

        if @cache_file
          @cache_file_queue << cache_key
          @cache_file_queue << value
        end

        @minimum_pushes_cache[cache_key] = value
      end
    end

    def cache_size
      @minimum_pushes_cache.size
    end
  end

  attr_accessor :joltages, :buttons, :original_to_s, :max_allowed_pushes, :top_level

  def initialize(joltages, buttons, top_level = true, max_allowed_pushes = nil)
    self.top_level = top_level if top_level

    self.joltages = joltages
    self.buttons = buttons

    normalize!

    unless @has_no_solution
      self.original_to_s = to_s if top_level

      if max_allowed_pushes
        self.max_allowed_pushes = max_allowed_pushes
      end
    end
  end

  def done? = joltages.done?

  def cannot_have_a_solution?
    @has_no_solution || buttons.empty?
  end

  def merge_joined_joltage_indices!
    buttons_to_index = {}

    0.upto(joltages.size - 1) do |joltage_index|
      buttons_key = buttons.select { it.include?(joltage_index) }

      if buttons_to_index.key?(buttons_key)
        to_check = buttons_to_index[buttons_key]

        to_check = [*to_check] unless to_check.is_a?(Array)

        to_check.each do |other_index|
          if joltages[joltage_index] != joltages[other_index]
            @has_no_solution = true
            return
          end
        end

        buttons_to_index[buttons_key] = [joltage_index, *to_check]
      else
        buttons_to_index[buttons_key] = joltage_index
      end
    end

    buttons_to_index.each_value do |indices|
      if indices.is_a?(Array)
        remove_joltage_indices(indices[1..].reverse)
      end
    end
  end

  def crude_max_pushes
    return @crude_max_pushes if defined?(@crude_max_pushes)

    @crude_max_pushes = crude_max_pushes_without_multiplier * multiplier
  end

  def crude_max_pushes_without_multiplier
    return @crude_max_pushes_without_multiplier if defined?(@crude_max_pushes_without_multiplier)

    @crude_max_pushes_without_multiplier = crude_max_pushes_without_multiplier_for(buttons, joltages)

    if max_allowed_pushes
      if max_allowed_pushes < @crude_max_pushes_without_multiplier
        @crude_max_pushes_without_multiplier = max_allowed_pushes
      end
    end

    @crude_max_pushes_without_multiplier
  end

  def crude_max_pushes_without_multiplier_for(buttons, joltages)
    better_max_pushes_estimate(buttons, joltages)
  end

  def crude_min_pushes
    return @crude_min_pushes if defined?(@crude_min_pushes)

    pushes = crude_min_pushes_without_multiplier

    @crude_min_pushes = if pushes
                          pushes * multiplier
                        end
  end

  def crude_min_pushes_without_multiplier
    @crude_min_pushes_without_multiplier ||= better_min_pushes_estimate2(buttons, joltages)
    # crude_min_pushes_without_multiplier_for(buttons, joltages)
  end

  def crude_min_pushes_without_multiplier_for(buttons, joltages)
    max_joltage_size = buttons.first.joltages_size

    joltages_sum = joltages.sum

    dividend = joltages_sum / max_joltage_size

    if joltages_sum % max_joltage_size == 0
      dividend
    else
      dividend + 1
    end
  end

  def minimum_pushes_required
    if top_level
      # puts "#{Time.now}: starting #{self}"
      $i ||= 0
      $i += 1
      $previous_time ||= Time.now
      $current_time = Time.now
      span = $current_time - $previous_time
      $total_time ||= 0
      $total_time += span
      puts "#{$current_time} #{span.to_i}s ##{$i} #{$total_time / $i} s/m cache: #{self.class.cache_size}"
      puts self
      $previous_time = $current_time
    end

    pushes = minimum_pushes_cached do
      minimum_pushes_required_without_cache
    end

    pushes && (pushes * multiplier)
  end

  # NOTE: This "private" method does not apply the multiplier!!
  def minimum_pushes_required_without_cache
    if cannot_have_a_solution?
      # if done?
      #   raise "wtf"
      #   binding.pry
      # end
      return nil
    end

    # target_button = buttons.first
    # target_button = button_with_highest_odd_to_even_ratio
    # target_button = most_impactful_button_with_lowest_joltage
    #
    # if target_button.nil?
    #   if done?
    #     return 0
    #   else
    #     return nil
    #   end
    # end

    # target_joltage_index = minimum_nonzero_joltage_index(target_button)
    # target_joltage_index = joltage_index_with_min_occurrences(target_button)
    # try
    # joltage index with most buttons
    # joltage index with fewest buttons
    # index of biggest joltage
    # index of smallest joltage
    # seems fast-ish!:
    # target_joltage_index = joltage_index_with_fewest_buttons
    # too slow:
    # target_joltage_index = joltage_index_of_biggest_joltage
    # seems fast-ish!
    # target_joltage_index = joltage_index_of_smallest_joltage
    # too slow:
    # target_joltage_index = joltage_index_with_most_buttons
    # seems fast-ish!
    target_joltage_index = index_of_min_joltage_for_biggest_buttons

    if target_joltage_index.nil?
      if done?
        return 0
      else
        return nil
      end
    end

    target_joltage = joltages[target_joltage_index]

    # worst_case_pushes = crude_max_pushes_without_multiplier - target_joltage

    relevant_buttons = buttons.select { |button| button.include?(target_joltage_index) }
    relevant_buttons.reject! do |button|
      button.joltages_to_increment.any? do |joltage_index|
        joltages[joltage_index].zero?
      end
    end

    worst_case_pushes = crude_max_pushes_without_multiplier - target_joltage

    minimum_submachine_pushes = nil

    relevant_buttons.button_presses(target_joltage) do |button_presses|
      # if top_level
      #   # puts "#{Time.now}: #{self} creating a submachine for #{worst_case_pushes}"
      # end

      new_joltages = joltages.dup
      button_presses.each { |button_press| button_press.push(new_joltages) }

      unless new_joltages.any?(&:negative?)
        if new_joltages.done?
          return target_joltage
        end

        new_buttons = buttons - relevant_buttons

        if new_buttons.empty?
          # if done?
          #   raise "wtf"
          #   binding.pry
          # end
          next
        end

        submachine = Machine.new(
          new_joltages,
          new_buttons,
          false,
          minimum_submachine_pushes
        )

        # should we cache the fact that this has no solution to skip checking it??
        # that would mean moving this check to the top so we don't skip caching
        # the submachine
        if submachine.cannot_have_a_solution?
          # if done?
          #   raise "wtf"
          #   binding.pry
          # end
          next
        end

        submachine_crude_min_pushes = submachine.crude_min_pushes

        # TODO: can we make use of min_submachine_pushes here? Or no because we short-circuit?
        # maybe we can go back to the faster _min_ instead of _most_ if we use it instead of returning?
        if submachine_crude_min_pushes
          if submachine_crude_min_pushes > worst_case_pushes
            # if done?
            #   raise "not expecting done!"
            #   binding.pry
            # end

            puts "would have skipped"
            next
          end
        # checking this again because min_crude_pushes can change it
        elsif submachine.cannot_have_a_solution?
          # if done?
          #   raise "wtf"
          #   binding.pry
          # end
          next
        end

        if minimum_submachine_pushes
          if submachine_crude_min_pushes >= minimum_submachine_pushes
            # puts "short circuit!!"
            next
          end

          # if max_allowed_pushes
          #   if submachine_crude_min_pushes > max_allowed_pushes
          #     # puts "short circuit2!"
          #     # raise "wtf!"
          #     next
          #   end
          # end
        end

        min_pushes = submachine.minimum_pushes_required

        if min_pushes
          # return target_joltage + min_pushes

          if minimum_submachine_pushes.nil? || min_pushes < minimum_submachine_pushes
            minimum_submachine_pushes = min_pushes
          end
        end
      end
    end

    if minimum_submachine_pushes
      #   binding.pry if top_level
      # else
      target_joltage + minimum_submachine_pushes
    end
  end

  def minimum_pushes_cached(&)
    self.class.minimum_pushes_cached(cache_key, &)
  end

  def button_with_most_joltage_indices
    buttons.max_by do |button|
      button.joltages_to_increment.count do |joltage_index|
        joltages[joltage_index].positive?
      end
    end
  end

  def joltage_index_with_most_occurrences(button)
    joltages_to_increment = button.joltages_to_increment

    joltages_to_increment.max_by do |joltage_index|
      buttons.count { it.include?(joltage_index) }
    end
  end

  def joltage_index_with_min_occurrences(button)
    button.joltages_to_increment.min_by do |joltage_index|
      buttons.count { it.include?(joltage_index) }
    end
  end

  def joltage_index_of_biggest_joltage
    max_joltage_index = 0
    max_joltage = joltages[0]

    1.upto(joltages_size - 1) do |index|
      joltage = joltages[index]

      if joltage > max_joltage
        max_joltage_index = index
        max_joltage = joltage
      end
    end

    max_joltage_index
  end

  def joltage_index_of_smallest_joltage
    min_joltage_index = 0
    min_joltage = joltages[0]

    1.upto(joltages_size - 1) do |index|
      joltage = joltages[index]

      if joltage < min_joltage
        min_joltage_index = index
        min_joltage = joltage
      end
    end

    min_joltage_index
  end

  def index_of_min_joltage_for_biggest_buttons
    button_index = 0
    button = buttons[0]
    button_size = button.joltages_size
    max_size = button_size

    min_joltage_index = nil
    min_joltage = nil

    while button_size == max_size
      button.joltages_to_increment.each do |joltage_index|
        joltage = joltages[joltage_index]

        if min_joltage.nil? || min_joltage > joltage
          min_joltage = joltage
          min_joltage_index = joltage_index
        end
      end

      button_index += 1
      button = buttons[button_index]

      return min_joltage_index unless button

      button_size = button.joltages_size
    end

    min_joltage_index
  end

  def joltage_index_with_fewest_buttons
    min_joltage_index = nil
    min_buttons_count = nil

    0.upto(joltages_size - 1) do |index|
      buttons_count = buttons.count { it.include?(index) }

      if min_joltage_index.nil? || buttons_count < min_buttons_count
        min_joltage_index = index
        min_buttons_count = buttons_count
      end
    end

    min_joltage_index
  end

  def joltage_index_with_most_buttons
    max_joltage_index = nil
    max_buttons_count = nil

    0.upto(joltages_size - 1) do |index|
      buttons_count = buttons.count { it.include?(index) }

      if max_joltage_index.nil? || buttons_count > max_buttons_count
        max_joltage_index = index
        max_buttons_count = buttons_count
      end
    end

    max_joltage_index
  end

  def most_impactful_button_with_lowest_joltage
    i = joltages.index_of_min

    buttons.find do |button|
      button.include?(i)
    end
  end

  def button_with_highest_odd_to_even_ratio
    buttons.max_by do |button|
      evens = 0
      odds = 0

      button.each do |joltage_index|
        if joltages[joltage_index].even?
          evens += 1
        else
          odds += 1
        end
      end

      if evens.zero?
        if odds.zero?
          raise "wtf"
        else
          1r
        end
      else
        odds.to_r / evens
      end
    end
  end

  def minimum_nonzero_joltage_index(button)
    joltages_to_increment = button.joltages_to_increment

    min_index = nil
    min_joltage = nil

    joltages_to_increment.each do |joltage_index|
      value = joltages[joltage_index]

      if value.positive? && (min_joltage.nil? || value < min_joltage)
        min_joltage = value
        min_index = joltage_index
      end
    end

    min_index
  end

  def multiplier
    @multiplier || 1
  end

  attr_writer :multiplier

  # Are we even really allowed to do this??
  def update_multiplier!
    gcd = joltages.gcd

    if gcd
      self.multiplier *= gcd
      self.joltages /= gcd

      if max_allowed_pushes
        if max_allowed_pushes % gcd == 0
          self.max_allowed_pushes /= gcd
        else
          self.max_allowed_pushes /= gcd
          self.max_allowed_pushes += 1
        end
      end

      clear_caches
    end
  end

  def clear_caches
    if instance_variable_defined?(:@crude_max_pushes)
      remove_instance_variable(:@crude_max_pushes)
    end
    if instance_variable_defined?(:@crude_max_pushes_without_multiplier)
      remove_instance_variable(:@crude_max_pushes_without_multiplier)
    end
    if instance_variable_defined?(:@crude_min_pushes)
      remove_instance_variable(:@crude_min_pushes)
    end
    if instance_variable_defined?(:@crude_min_pushes_without_multiplier)
      remove_instance_variable(:@crude_min_pushes_without_multiplier)
    end
  end

  def joltages_size = joltages.size
  def joltage_levels = joltages.joltage_levels

  def to_s
    s = "#{buttons.map(&:to_s).join(" ")} #{joltages} cache size: #{self.class.cache_size}"

    if multiplier > 1
      s += " x#{multiplier}"
    end

    if original_to_s
      "#{s} originally: #{original_to_s}"
    else
      s
    end
  end

  # Normalize to allow for more cache hits
  def normalize!
    remove_all_zero_joltages!
    update_multiplier!
    order_joltages!
    order_buttons!
    merge_joined_joltage_indices!

    unless @has_no_solution
      crude_max_pushes_without_multiplier
    end
  end

  def remove_all_zero_joltages!
    indices_to_remove = []

    joltages.each.with_index do |joltage_level, index|
      if joltage_level.zero?
        indices_to_remove << index
      end
    end

    return if indices_to_remove.empty?

    remove_joltage_indices(indices_to_remove)
  end

  def remove_joltage_indices(indices_to_remove)
    updated_joltages = []

    joltages.each.with_index do |joltage_level, index|
      unless indices_to_remove.include?(index)
        updated_joltages << joltage_level
      end
    end

    self.joltages = Joltages.new(updated_joltages)

    indices_to_remove.reverse!

    indices_to_remove.each do |index|
      buttons.map! do |button|
        new_joltages = button.joltages_to_increment.map do |joltage_index|
          if joltage_index > index
            joltage_index - 1
          elsif joltage_index < index
            joltage_index
          end
        end

        new_joltages.compact!

        next if new_joltages.empty?

        if button.joltages_to_increment == new_joltages
          button
        else
          Button.new(new_joltages)
        end
      end

      buttons.compact!
      buttons.uniq!
    end

    clear_caches
    order_buttons!
  end

  def order_joltages!
    already_in_order = true

    joltage_levels.inject do |joltage_level_1, joltage_level_2|
      if joltage_level_2 < joltage_level_1
        already_in_order = false
        break
      end

      joltage_level_2
    end

    return if already_in_order

    joltage_index_map = joltage_levels.map.with_index do |level, index|
      [level, index]
    end

    sorted_joltage_index_map = joltage_index_map
    sorted_joltage_index_map.sort!

    self.joltages = Joltages.new(sorted_joltage_index_map.map(&:first))

    joltage_index_map = sorted_joltage_index_map.map(&:last).map.with_index do |old_index, new_index|
      [old_index, new_index]
    end.to_h

    buttons.map! do |button|
      new_joltage_indices = button.joltages_to_increment.map do |old_joltage_index|
        joltage_index_map[old_joltage_index]
      end

      Button.new(new_joltage_indices).tap(&:sort_joltage_indices!)
    end
  end

  def order_buttons!
    buttons.sort_by!(&:joltages_to_increment)
    buttons.sort_by! { |button| -button.joltages_size }
  end

  def hash
    # rubocop:disable Security/CompoundHash
    buttons.hash ^ joltages.hash
    # rubocop:enable Security/CompoundHash
  end

  def ==(other)
    other.is_a?(Machine) && joltages == other.joltages && buttons == other.buttons
  end

  def eql?(other) = self == other

  def cache_key
    a = []

    buttons.each do |button|
      button.joltages_to_increment.each do |joltage_index|
        a << joltage_index
      end

      a << 10
    end

    joltages.joltage_levels.each do |joltage_level|
      a << joltage_level
    end

    a
  end

  def better_max_pushes_estimate(buttons, joltages)
    joltages = joltages.dup

    # group buttons by joltage index
    # map these to the smallest button per joltage index
    # take the biggest of these buttons
    # apply it until its targets are negative or zero
    # repeat if not done
    #
    # use this number of pushes as the worst-case-scenario to short-circuit more

    smallest_button_per_index = []
    pushes = 0

    buttons.each do |button|
      button_size = button.joltages_size

      button.each do |joltage_index|
        smallest_button = smallest_button_per_index[joltage_index]

        if smallest_button.nil? || smallest_button.joltages_size > button_size
          smallest_button_per_index[joltage_index] = button
        end
      end
    end

    a = []

    0.upto(joltages.size - 1) do |joltage_index|
      button = smallest_button_per_index[joltage_index]

      unless button
        @has_no_solution = true
        return
      end

      a << [button, joltage_index]
    end

    smallest_button_per_index = a

    smallest_button_per_index.sort_by! { |a| a.first.joltages_size }

    smallest_button_per_index.each do |(button, joltage_index)|
      joltage = joltages[joltage_index]

      if joltage > 0
        pushes += joltage
        button.push_multiple(joltages, joltage)
      end
    end

    pushes
  rescue => e
    binding.pry
    raise
  end

  # WARNING: this doesn't look right... we'd need to do something about the negative values
  def better_min_pushes_estimate
    buttons = self.buttons
    joltages = self.joltages.dup

    # group buttons by joltage index
    # map these to the smallest button per joltage index
    # take the biggest of these buttons
    # apply it until its targets are negative or zero
    # repeat if not done
    #
    # use this number of pushes as the worst-case-scenario to short-circuit more

    biggest_button_per_index = []
    pushes = 0

    buttons.each do |button|
      button_size = button.joltages_size

      button.each do |joltage_index|
        biggest_button = biggest_button_per_index[joltage_index]

        if biggest_button.nil? || biggest_button.joltages_size < button_size
          biggest_button_per_index[joltage_index] = button
        end
      end
    end

    a = []

    0.upto(joltages.size - 1) do |joltage_index|
      button = biggest_button_per_index[joltage_index]

      unless button
        @has_no_solution = true
        return
      end

      a << [button, joltage_index]
    end

    biggest_button_per_index = a

    biggest_button_per_index.sort_by! { |a| a.first.joltages_size }
    biggest_button_per_index.reverse!

    biggest_button_per_index.each do |(button, joltage_index)|
      joltage = joltages[joltage_index]

      if joltage > 0
        pushes += joltage
        button.push_multiple(joltages, joltage)
      end
    end

    binding.pry

    pushes
  rescue => e
    binding.pry
    raise
  end

  def better_min_pushes_estimate2(buttons, joltages)
    crude_min = crude_min_pushes_without_multiplier_for(buttons, joltages)

    levels = joltages.joltage_levels.reverse

    button_sizes = buttons.map(&:joltages_size)

    pushes = 0

    until levels.empty?
      button_size = button_sizes.shift
      covered_levels = levels.shift(button_size)
      pushes += covered_levels.first

      if crude_min < pushes
        return crude_min
      end
    end

    pushes
  end
end
