class Array
  def choose(size)
    if size == 1
      self
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
end
