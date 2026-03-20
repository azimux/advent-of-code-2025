require_relative "cache_thread"

class Network
  attr_accessor :graph, :inputs_file_name

  def initialize(inputs_file_name)
    self.inputs_file_name = inputs_file_name

    inputs = File.read(inputs_file_name)

    lines = inputs.split("\n")

    self.graph = {}

    lines.each do |line|
      if line =~ /(\w+):(.*)/
        source = $1
        destination = $2.scan(/\w+/)

        graph[source.to_sym] = destination.map(&:to_sym)
      else
        raise "Unexpected line #{line}"
      end
    end
  end

  def [](key) = graph[key]
end
