class Array
  def choose(size)
    if size == 1
      each { yield [it] }
    else
      (0..(self.size - size)).each do |index|
        first = self[index]
        rest = self[(index + 1)..]

        rest.choose(size - 1) do |group|
          yield [first, *group]
        end
      end
    end
  end

  # TODO: build these one at a time and yield them instead of building them all upfront
  def choose_allowing_repetition(size)
    new_size = size * self.size

    puts "allocating #{new_size}"
    a = Array.new(new_size)

    each.with_index do |value, i|
      size.times do |j|
        a[(i * size) + j] = value
      end
    end

    values = Set.new
    a.choose(size) { |e| values << e }
    values.to_a
  end
end
