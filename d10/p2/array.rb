class Array
  def choose(size)
    if size == 1
      map { [it] }
    else
      result = []

      (0..(self.size - size)).each do |index|
        first = self[index]
        rest = self[(index + 1)..]

        rest.choose(size - 1).each do |group|
          result << [first, *group]
        end
      end

      result
    end
  end

  def choose_allowing_repetition(size)
    new_size = size * self.size

    puts "allocating #{new_size}"
    a = Array.new(new_size)

    each.with_index do |value, i|
      size.times do |j|
        a[(i * size) + j] = value
      end
    end

    a.choose(size)
  end
end
