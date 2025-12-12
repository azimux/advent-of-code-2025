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
  end
end
