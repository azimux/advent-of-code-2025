class NetworkPath
  @existing = {}

  class << self
    def new(value, list = nil)
      key = [value, list]

      @existing[key] ||= super
    end
  end

  attr_accessor :value, :list

  def initialize(value, list = nil)
    self.value = value
    self.list = list
  end

  def each_part(&block)
    block.call(value)

    list&.each_part(&block)
  end

  def hash
    # rubocop:disable Security/CompoundHash
    value.hash + list.hash
    # rubocop:enable Security/CompoundHash
  end

  def ==(other)
    other.class == self.class && other.value == value && other.list == list
  end

  def eql?(other) = self == other
end
