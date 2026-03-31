require_relative "present_shape"
require_relative "region"

class PresentsAndRegions
  attr_accessor :present_shapes, :regions

  def initialize(inputs_file)
    presents_regex = /^(\d+):\n((?:[.#]+\n)+)/

    inputs_file_text = File.read(inputs_file)

    self.present_shapes = inputs_file_text.scan(presents_regex).map do |(index, dots)|
      PresentShape.new(index.to_i, dots_to_spaces(dots))
    end

    regions_regex = /^(\d+)x(\d+):\s+((?:\d+(?:\s+|$))+)/

    self.regions = inputs_file_text.scan(regions_regex).map do |(height, width, present_counts)|
      present_counts = present_counts.chomp.split(/\s+|$/).map(&:to_i)

      Region.new(height: height.to_i, width: width.to_i, present_counts:)
    end
  end

  def dots_to_spaces(dots_string)
    lines = dots_string.chomp.split("\n")

    lines.map! do |line|
      line.chars.map { it == "#" }
    end
  end
end
