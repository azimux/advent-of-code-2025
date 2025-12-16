require_relative "vertex"
require_relative "rectangle"

class Ring
  attr_accessor :head, :size

  def initialize(points_or_vertex)
    if points_or_vertex.is_a?(Vertex)
      self.head = points_or_vertex
      self.size = points.size

      return
    end

    points = points_or_vertex

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

  def vertices
    vertex = head

    return [] unless head

    vertices = []
    begin
      vertices << vertex
      vertex = vertex.next
    end until vertex == head

    vertices
  end

  def points
    vertices.map(&:point)
  end

  def empty? = size == 0

  def extract_rectangles
    rectangles = []
    rings = [self]

    until rings.empty?
      ring = rings.shift
      next if ring.empty?

      new_rectangle, new_rings = ring.extract_rectangle
      rings = [*rings, *new_rings]
      rectangles << new_rectangle if new_rectangle
    end

    rectangles
  end

  def extract_rectangle
    if size == 2
      # vs = vertices
      # rectangle = Rectangle.new(vs.first, vs.last)

      self.size = 0
      self.head = nil

      # return [rectangle, []]
      return [nil, []]
    end

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
        new_y2 = contained_red_vertices.map(&:point).min.y

        potential_new_neighbors = contained_red_vertices.select { it.y == new_y2 }

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

    new_bottom_right = Point[top_right.x, new_y2]

    tr_delete = false
    if new_bottom_right == bottom_right
      tr_deleted = true
      delete(top_right_vertex)
    else
      top_right_vertex.y = new_y2
    end

    rings = if potential_new_neighbors.nil? || potential_new_neighbors.empty?
              [self]
            else
              patch_up_new_neighbors(
                [top_left_vertex,
                 *potential_new_neighbors,
                 top_right_vertex]
              )
            end

    [green_rectangle, rings]
  end

  def patch_up_new_neighbors(to_patch_up)
    to_patch_up = to_patch_up.sort
    candidate_rings = []

    to_patch_up.each_slice(2) do |(left_neighbor, right_neighbor)|
      candidate_rings << left_neighbor

      left_neighbor.update_horizontal_neighbor(right_neighbor)
      right_neighbor.update_horizontal_neighbor(left_neighbor)
    end

    candidate_rings.map! { Ring.new(it) }
    candidate_rings.each(&:normalize_head)
    candidate_rings.uniq!(&:head)
    candidate_rings
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

  def to_s = points.map(&:to_s)
end
