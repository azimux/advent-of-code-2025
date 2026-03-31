require_relative "present"
require_relative "region"

class PresentsAndRegions
  attr_accessor :presents, :regions

  def initialize(inputs_file)
    presents_regex = /^(\d+):\n((?:[.#]+\n)+)/

    inputs_file_text = File.read(inputs_file)

    self.presents = inputs_file_text.scan(presents_regex).map do |(index, spaces)|
      Present.new(index.to_i, spaces.chomp.split("\n"))
    end

    regions_regex = /^(\d+)x(\d+):\s+((?:\d+(?:\s+|$))+)/

    self.regions = inputs_file_text.scan(regions_regex).map do |(height, width, present_counts)|
      present_counts = present_counts.chomp.split(/\s+|$/).map(&:to_i)

      Region.new(height: height.to_i, width: width.to_i, present_counts:)
    end
  end
end
