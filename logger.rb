module Logger
  RGB_COLOR_MAP = {
    cyan: "139;233;253",
    green: "80;250;123",
    red: "255;85;85",
    white: "255;255;255"
  }.freeze

  def self.request(requestLine)
    rgb_val = RGB_COLOR_MAP[:green] 
    puts("\e[38;2;#{rgb_val}m[#{Time.now.utc.iso8601(3)}] #{requestLine[:method]} #{requestLine[:target]} #{requestLine[:version]}\e[0m")
  end

  def self.error(message)
    rgb_val = RGB_COLOR_MAP[:red] 
    puts("\e[38;2;#{rgb_val}m[#{Time.now.utc.iso8601(3)}] #{message}\e[0m")
  end

  def self.message(message)
    rgb_val = RGB_COLOR_MAP[:cyan] 
    puts("\e[38;2;#{rgb_val}m#{message}\e[0m")
  end
end
