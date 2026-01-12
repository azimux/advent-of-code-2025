require_relative "array"

class Machine
  class << self
    attr_accessor :strategy, :skip_multiplier, :short_circuit
  end

  attr_accessor :joltages, :buttons, :original_to_s, :max_allowed_pushes, :top_level

  def initialize(joltages, buttons, top_level = true, max_allowed_pushes = nil)
    self.top_level = top_level if top_level
    self.max_allowed_pushes = max_allowed_pushes if max_allowed_pushes

    self.joltages = joltages
    self.buttons = buttons

    self.original_to_s = to_s if top_level

    normalize!
  end

  def done? = joltages.done?

  def cannot_have_a_solution?
    return @cannot_have_a_solution if defined?(@cannot_have_a_solution)

    @cannot_have_a_solution = buttons.empty? ||
                              (max_allowed_pushes && crude_min_pushes > max_allowed_pushes)
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
            @cannot_have_a_solution = true
            return
          end
        end

        buttons_to_index[buttons_key] = [joltage_index, *to_check]
      else
        buttons_to_index[buttons_key] = joltage_index
      end
    end

    indices_to_remove = []

    buttons_to_index.each_value do |indices|
      if indices.is_a?(Array)
        indices_to_remove += indices[1..]
      end
    end

    remove_joltage_indices(indices_to_remove)
  end

  def crude_max_pushes
    return @crude_max_pushes if defined?(@crude_max_pushes)

    @crude_max_pushes = crude_max_pushes_for(buttons, joltages)
  end

  def crude_max_pushes_for(buttons, joltages)
    better_max_pushes_estimate(buttons, joltages)
  end

  def crude_min_pushes
    return @crude_min_pushes if defined?(@crude_min_pushes)

    @crude_min_pushes = better_min_pushes_estimate2(buttons, joltages)
  end

  def crude_min_pushes_for(buttons, joltages)
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
      puts "#{$current_time} #{span.to_i}s ##{$i} #{$total_time / $i} s/m cache: #{MinimumPushesCache.cache_size}"
      puts self
      $previous_time = $current_time
    end

    pushes = minimum_pushes_cached do
      minimum_pushes_required_without_cache
    end

    pushes && (pushes * multiplier)
  end

  def minimum_pushes_required_without_cache
    return if cannot_have_a_solution?

    unless joltages_covered_by_buttons?
      raise "yay!!"
      return
    end

    split_solution = split_machine_solution
    return split_solution if split_solution

    # seems fast-ish!:
    # target_joltage_index = joltage_index_with_fewest_buttons
    # too slow:
    # target_joltage_index = joltage_index_of_biggest_joltage
    # seems fast-ish!
    # target_joltage_index = joltage_index_of_smallest_joltage
    # too slow:
    # target_joltage_index = joltage_index_with_most_buttons
    # seems fast-ish!
    # target_joltage_index = index_of_min_joltage_for_biggest_buttons
    # seems even faster!! (ish?) [inputs.cache]
    # target_joltage_index = index_of_fewest_button_joltage_for_biggest_buttons
    target_joltage_index = send(Machine.strategy)

    if target_joltage_index.nil?
      return done? ? 0 : nil
    end

    target_joltage = joltages[target_joltage_index]

    relevant_buttons = buttons.select { |button| button.include?(target_joltage_index) }
    relevant_buttons.reject! do |button|
      button.joltages_to_increment.any? do |joltage_index|
        joltages[joltage_index].zero?
      end
    end

    worst_case_pushes = crude_max_pushes - target_joltage

    minimum_submachine_pushes = nil

    new_buttons = buttons - relevant_buttons

    relevant_buttons.button_presses(target_joltage) do |button_presses|
      new_joltages = joltages.dup
      button_presses.each { |button_press| button_press.push(new_joltages) }

      # Is there a way we can break out of this loop?
      # Each set of button presses should be less and less impactful, leaving us further
      # and further from a solution. Can't we short circuit using this info??

      unless new_joltages.any?(&:negative?)
        return target_joltage if new_joltages.done?

        # We don't want to create a machine with no buttons
        next if new_buttons.empty?

        cap = worst_case_pushes

        if minimum_submachine_pushes
          if cap == minimum_submachine_pushes
            # Is this OK?? should be!
            return minimum_submachine_pushes + target_joltage
          elsif cap > minimum_submachine_pushes
            cap = minimum_submachine_pushes - 1
          end
        end

        if max_allowed_pushes
          new_cap = max_allowed_pushes - target_joltage

          if cap > new_cap
            cap = new_cap
          end
        end

        submachine = Machine.new(new_joltages, new_buttons.dup, false, cap)

        next if submachine.cannot_have_a_solution?

        min_pushes = submachine.minimum_pushes_required

        if min_pushes
          if Machine.short_circuit
            return target_joltage + min_pushes
          end

          if minimum_submachine_pushes.nil? || min_pushes < minimum_submachine_pushes
            minimum_submachine_pushes = min_pushes
          end
        end
      end
    end

    if minimum_submachine_pushes
      target_joltage + minimum_submachine_pushes
    end
  end

  def split_machine_solution
    independent_machines = split_machine

    if independent_machines
      sum = nil

      independent_machines.each do |machine|
        presses = machine.minimum_pushes_required
        return unless presses

        sum = if sum
                sum + presses
              else
                presses
              end
      end

      sum
    end
  end

  def joltages_covered_by_buttons?
    if joltage_levels.any?(&:zero?)
      raise "wtf"
    end

    covered = Array.new(joltage_levels.size)

    buttons.each do |button|
      button.joltages_to_increment.each do |joltage_index|
        covered[joltage_index] = true
      end
    end

    covered.all?
  end

  def minimum_pushes_cached(&)
    MinimumPushesCache.minimum_pushes_cached(self, &)
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

  def index_of_fewest_button_joltage_for_biggest_buttons
    button_index = 0
    button = buttons[0]

    max_size = button_size = button.joltages_size

    joltages_indices_to_consider = []

    while button_size == max_size
      button.joltages_to_increment.each do |joltage_index|
        unless joltages_indices_to_consider.include?(joltage_index)
          joltages_indices_to_consider << joltage_index
        end
      end

      button_index += 1
      button = buttons[button_index]

      break unless button

      button_size = button.joltages_size
    end

    joltages_indices_to_consider.min_by do |joltage_index|
      buttons.count { it.include?(joltage_index) }
    end
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
    if instance_variable_defined?(:@crude_min_pushes)
      remove_instance_variable(:@crude_min_pushes)
    end
  end

  def joltages_size = joltages.size
  def joltage_levels = joltages.joltage_levels

  def to_s
    s = "#{buttons.map(&:to_s).join(" ")} #{joltages} cache size: #{MinimumPushesCache.cache_size}"

    if multiplier > 1
      s += " x#{multiplier}"
    end

    if original_to_s
      "#{s} originally: #{original_to_s}"
    else
      s
    end
  end

  def to_s_parsable
    "#{buttons.map(&:to_s).join(" ")} #{joltages}"
  end

  # Normalize to allow for more cache hits
  def normalize!
    remove_all_zero_joltages!
    update_multiplier! unless Machine.skip_multiplier
    order_joltages!
    order_buttons!
    merge_joined_joltage_indices!

    unless @cannot_have_a_solution
      crude_max_pushes
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

    self.buttons = buttons.reject do |button|
      button.joltages_to_increment.intersect?(indices_to_remove)
    end

    remove_joltage_indices(indices_to_remove)
  end

  def remove_joltage_indices(indices_to_remove)
    return if indices_to_remove.empty?

    updated_joltages = []

    joltages.each.with_index do |joltage_level, index|
      unless indices_to_remove.include?(index)
        updated_joltages << joltage_level
      end
    end

    self.joltages = Joltages.new(updated_joltages)

    indices_to_remove = indices_to_remove.sort
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

      a << -1
    end

    joltages.joltage_levels.each do |joltage_level|
      a << joltage_level
    end

    a
  end

  def better_max_pushes_estimate(buttons, joltages)
    joltages = joltages.dup

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
        @cannot_have_a_solution = true
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
  end

  # WARNING: this doesn't look right... we'd need to do something about the negative values
  def better_min_pushes_estimate
    buttons = self.buttons
    joltages = self.joltages.dup

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
        @cannot_have_a_solution = true
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

    pushes
  end

  def better_min_pushes_estimate2(buttons, joltages)
    crude_min = crude_min_pushes_for(buttons, joltages)

    levels = joltages.joltage_levels.reverse

    button_sizes = buttons.map(&:joltages_size)

    pushes = 0

    until levels.empty?
      button_size = button_sizes.shift
      covered_levels = levels.shift(button_size)
      pushes += covered_levels.first

      if crude_min < pushes
        # unreachable?
        return crude_min
      end
    end

    pushes
  end

  def non_overlapping_button_groups
    groups = []

    0.upto(buttons.size - 1) do |button_index|
      button = buttons[button_index]

      groups_containing_button = groups.select do |group|
        button.joltages_to_increment.any? do |joltage_index|
          group.any? do |group_button|
            group_button.include?(joltage_index)
          end
        end
      end

      case groups_containing_button.size
      when 0
        groups << [button]
      when 1
        groups_containing_button[0] << button
      else
        to_keep, *to_delete = groups_containing_button

        to_delete.each do |group_to_delete|
          groups.delete(group_to_delete)

          group_to_delete.each do |button|
            to_keep << button
          end
        end

        to_keep << button
      end
    end

    groups
  end

  def split_machine
    groups = non_overlapping_button_groups
    groups_size = groups.size

    if groups_size == 1
      return
    end

    groups.map do |buttons|
      joltage_indices = []

      buttons.each do |button|
        button.joltages_to_increment.each do |joltage_index|
          unless joltage_indices.include?(joltage_index)
            joltage_indices << joltage_index
          end
        end
      end

      new_joltages = []

      joltages.joltage_levels.each.with_index do |joltage_level, joltage_index|
        new_joltages << if joltage_indices.include?(joltage_index)
                          joltage_level
                        else
                          0
                        end
      end

      Machine.new(Joltages.new(new_joltages), buttons, false)
    end
  end
end
