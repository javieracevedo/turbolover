module Logger
  def self.logRequest(requestLine)
      puts("[#{Time.now.utc.iso8601(3)}] #{requestLine[:method]} #{requestLine[:target]} #{requestLine[:version]}")
  end
end
