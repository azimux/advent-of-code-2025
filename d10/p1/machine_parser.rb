require_relative "machine"
require_relative "button"

class MachineParser
  class << self
    def light_diagram_regex = /\[([.#]+)\]/
    def button_wiring_regex = /\((?:\d+,)*\d+\)/
    def buttons_wiring_regex = /((?:#{button_wiring_regex}\s*)+)/
    def joltage_regex = /\{(?:\d+,)*\d+}/
    def joltages_regex = /(#{joltage_regex}\s*)+/
    def machine_regex = /\A#{light_diagram_regex}\s*#{buttons_wiring_regex}\s*#{joltages_regex}\z/

    def parse(file_name)
      machines = []

      File.foreach(file_name) do |line|
        machines << parse_line(line)
      end

      machines
    end

    def parse_line(line)
      if line =~ machine_regex
        light_diagram = $1.strip
        buttons_wiring = $2.strip
        joltages = $3.strip
      else
        raise "Could not parse #{line}"
      end

      light_panel = LightPanel.new(light_diagram)
      light_count = light_panel.size

      buttons = buttons_wiring.scan(button_wiring_regex).map do |button_text|
        light_indexes = button_text.gsub(/[()]/, "").split(",").map(&:to_i)
        Button.new(light_indexes, light_count)
      end

      Machine.new(light_panel, buttons)
    end
  end
end
