require_relative "vertex"
require_relative "rectangle"

class Ring
  attr_accessor :head, :size

  def initialize(points)
    points = points.map(&:dup)

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

    normalize_head
  end

  def normalize_head
    self.head = smallest_vertex
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

  def empty? = size == 0

  def yet_another_extract_rectangles
    # start at head
    # Does head
  end

  def extract_rectangles
    rectangles = []

    until empty?
      new_rectangles = extract_rectangle
      rectangles += [*new_rectangles]
    end

    rectangles
  end

  def extract_rectangle
    top_left_vertex = smallest_vertex
    top_right_vertex = top_left_vertex.right
    bottom_left_vertex = top_left_vertex.down
    bottom_right_vertex = top_right_vertex.down

    top_left = top_left_vertex.point
    top_right = top_right_vertex.point
    bottom_left = bottom_left_vertex.point
    bottom_right = bottom_right_vertex.point

    bl_y = bottom_left.y
    br_y = bottom_right.y

    green_rectangle_y2 = bl_y < br_y ? bl_y : br_y

    candidate_green_rectangle = Rectangle.new(top_left, Point[top_right.x, green_rectangle_y2])

    if candidate_green_rectangle.height > 2 && candidate_green_rectangle.width > 2
      inner_rectangle = Rectangle.new(
        Point[candidate_green_rectangle.x1 + 1, candidate_green_rectangle.y1 + 1],
        Point[candidate_green_rectangle.x2 - 1, candidate_green_rectangle.y2 - 1]
      )

      contained_red_vertices = vertices.select { inner_rectangle.contains?(it.point) }

      unless contained_red_vertices.empty?
        new_y2 = contained_red_vertices.map(&:point).sort.first.y

        potential_new_neighbors = contained_red_vertices.select { it.y == new_y }

        candidate_green_rectangle = Rectangle.new(
          candidate_green_rectangle.ul,
          Point[candidate_green_rectangle.x2, new_y2]
        )
      end
    end

    # We need this to be a collection and optionally strip off a row of
    # 1 tile tall rectangles off the top to normalize things.
    green_rectangle = candidate_green_rectangle

    new_y2 = green_rectangle.y2

    new_bottom_left = Point[top_left.x, new_y2]

    tl_deleted = false

    if new_bottom_left == bottom_left
      tl_deleted = true
      delete(top_left_vertex)
    else
      top_left_vertex.y = new_y2
    end

    tr_deleted = false
    new_bottom_right = Point[top_right.x, new_y2]

    if new_bottom_right == bottom_right
      tr_deleted = true
      delete(top_right_vertex)
    else
      top_right_vertex.y = new_y2
    end

    unless tl_deleted
      if top_left_vertex.next.y == top_left_vertex.y
        neighbor = top_left_vertex.next
        neighbor_distance = top_left_vertex.distance_to(neighbor)

        new_neighbor = potential_new_neighbors.find { top_left_vertex.distance_to(it) < neighbor_distance }

        if new_neighbor
          top_left_vertex.next = new_neighbor
        end
        asdfasdf
      end
      if top_left_vertex.acute?
        closest = top_left_vertex.closest_neighbor
        top_left_vertex.next = closest
        top_left_vertex.prev = closest
      elsif top_left_vertex.obtuse?
        delete(top_left_vertex)
      end
    end

    unless tr_deleted
      if top_right_vertex.acute?
        closest = top_right_vertex.closest_neighbor
        top_right_vertex.next = closest
        top_right_vertex.prev = closest
      elsif top_right_vertex.obtuse?
        delete(top_right_vertex)
      end
    end

    if bottom_left_vertex.obtuse?
      delete(bottom_left_vertex)
    end

    if bottom_right_vertex.obtuse?
      delete(bottom_right_vertex)
    end

    green_rectangle
  end

  def extract_rectangle_old
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
