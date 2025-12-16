class Ring
  class Vertex
    include Comparable

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

    def update_horizontal_neighbor(new_neighbor)
      if horizontal_neighbor_is_next?
        self.next = new_neighbor
      elsif horizontal_neighbor_is_prev?
        self.prev = new_neighbor
      else
        binding.pry
        raise "wtf"
      end
    end

    def horizontal_neighbor_is_prev?
      prev.y == y
    end

    def horizontal_neighbor_is_next?
      self.next.y == y
    end

    def y = point.y
    def x = point.x
    def to_s = point.to_s

    def y=(y)
      self.point = Point.new(point.x, y)
    end

    def vertical? = prev.x == self.next.x
    def horizontal? = prev.y == self.next.y

    def closest_neighbor
      [prev, self.next].min_by { distance_to(it) }
    end

    def distance_to(other_vertex)
      (other_vertex.x - x).abs + (other_vertex.y - y).abs
    end

    def acute? = line? && !obtuse?
    def line? = vertical? || horizontal?

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

    def <=>(other) = point <=> other.point
  end
end
