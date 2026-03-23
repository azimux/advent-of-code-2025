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

  def has_cycles?(node, seen = Set.new, has_no_cycles = Set.new)
    return false if has_no_cycles.include?(node)
    return true if seen.include?(node)

    destinations = graph[node]

    unless destinations
      puts "#{node} has no cycles!"
      has_no_cycles << node
      return false
    end

    seen |= Set[node]

    return true if destinations.any? do |destination|
      has_cycles?(destination, seen, has_no_cycles)
    end

    puts "#{node} has no cycles!"
    has_no_cycles << node

    false
  end
end
