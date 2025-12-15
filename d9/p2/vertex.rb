class Ring
  class Vertex
    attr_accessor :point, :prev, :next

    def initialize(point)
      self.point = point
    end

    def right
      vertex = if prev.y == y
                 prev
               elsif self.next.y == y
                 self.next
               end

      if vertex && vertex.x > x
        vertex
      end
    end

    def down
      vertex = if prev.x == x
                 prev
               elsif self.next.x == x
                 self.next
               end

      if vertex && vertex.y > y
        vertex
      end
    end

    def y = point.y
    def x = point.x
    def to_s = point.to_s

    def y=(y)
      self.point = Point.new(point.x, y)
    end

    def obtuse?
      prev_x = prev.x
      next_x = self.next.x

      unless prev_x < next_x
        prev_x, next_x = next_x, prev_x
      end

      if prev_x == x && next_x == x
        x.between?(prev_x, next_x)
      else
        prev_y = prev.y
        next_y = self.next.y

        unless prev_y < next_y
          prev_y, next_y = next_y, prev_y
        end

        if prev_y == y && next_y == y
          y.between?(prev_y, next_y)
        end
      end
    end
  end
end
