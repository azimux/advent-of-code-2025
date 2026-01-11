module Caps
  class << self
    attr_accessor :caps_file

    def caps
      return @caps if defined?(@caps)

      raise "wtf" unless caps_file

      @caps = if File.exist?(caps_file)
                YAML.load_file(caps_file)
              else
                {}
              end
    end

    def update_cap_if_needed(machine, new_count)
      caps_key = machine.to_s_parsable
      cap = caps[caps_key]

      if cap.nil? || cap > new_count
        caps[caps_key] = new_count

        File.write(caps_file, YAML.dump(caps))
      elsif new_count > cap
        puts "unexpected worse push_count: #{new_count} > #{cap} for: #{caps_key}"
        raise "wtf how can we have a solution above the cap???"
      end
    end
  end
end
