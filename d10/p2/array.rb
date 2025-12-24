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
end
