require_relative "vertex"
require_relative "rectangle"

class Ring
  attr_accessor :head, :size

  def initialize(points)
    points = points.dup

    self.size = points.size

    first_point = points.first

    vertex = Vertex.new(first_point)
    self.head = vertex
    prev_vertex = vertex

    points[1..].each do |point|
      next_vertex = Vertex.new(point)
      prev_vertex.next = next_vertex
      next_vertex.prev = prev_vertex

      prev_vertex = next_vertex
    end

    prev_vertex.next = head
    head.prev = prev_vertex
  end

  def delete(point_or_vertex)
    case point_or_vertex
    when Point
      vertex = head

      size.times do
        if vertex.point == point_or_vertex
          return delete_vertex(vertex)
        end

        vertex = vertex.next
      end
    when Vertex
      delete_vertex(point_or_vertex)
    end
  end

  def delete_vertex(vertex)
    if size == 1
      self.size = 0
      self.head = nil
    else
      self.size -= 1

      prev_vertex = vertex.prev
      next_vertex = vertex.next

      if vertex == head
        self.head = next_vertex
      end

      prev_vertex.next = next_vertex
      next_vertex.prev = prev_vertex
    end
  end

  def points
    vertex = head
    points = []

    return points unless head

    begin
      points << vertex.point
      vertex = vertex.next
    end until vertex == head

    points
  end

  def empty?
    size == 0
  end

  def extract_rectangles
    rectangles = []
    rectangles << extract_rectangle until empty?
    rectangles
  end

  def extract_rectangle
    top_left = smallest_vertex

    top_right = top_left.right

    bottom_left = top_left.down
    bottom_right = top_right.down

    rectangle = nil

    if bottom_left.y > bottom_right.y
      rectangle = Rectangle.new(top_left.point, bottom_right.point)

      delete(top_right)
      top_left.y = bottom_right.y

      delete(bottom_right)
    elsif bottom_left.y < bottom_right.y
      rectangle = Rectangle.new(top_right.point, bottom_left.point)

      delete(top_left)
      top_right.y = bottom_left.y

      delete(bottom_left)
    else
      rectangle = Rectangle.new(top_left.point, bottom_right.point)

      delete(top_left)
      delete(bottom_left)
      delete(top_right)
      delete(bottom_right)
    end

    rectangle
  end

  def smallest_vertex
    return head if size == 1

    smallest_vertex = head
    smallest_point = head.point
    vertex = head.next

    begin
      vertex_point = vertex.point

      if vertex_point < smallest_point
        smallest_vertex = vertex
        smallest_point = vertex_point
      end

      vertex = vertex.next
    end until vertex == head

    smallest_vertex
  end
end
