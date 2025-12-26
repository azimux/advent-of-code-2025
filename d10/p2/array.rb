class Array
  def choose_allowing_repetition(group_size, &block)
    return if empty?

    if size == 1
      block.call(Array.new(group_size, first))
    else
      first_element, *rest = self

      group_size.downto(1) do |number_of_first_element_occurrences|
        entry = [first_element] * number_of_first_element_occurrences

        remaining_size = group_size - number_of_first_element_occurrences

        if remaining_size.zero?
          block.call(entry)
        else
          rest.choose_allowing_repetition(remaining_size) do |group|
            block.call([*entry, *group])
          end
        end
      end

      rest.choose_allowing_repetition(group_size, &block)
    end

    nil
  end
end
