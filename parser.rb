module Parser
  VALID_HTTP_METHODS = %w[GET POST PUT DELETE HEAD OPTIONS PATCH]

  class InvalidHTTPVersionError < StandardError; end
  class InvalidHTTPMethodError < StandardError; end
  class MalformedRequestLineError < StandardError; end
  class EmptyRequestLineError < StandardError; end

  def self.parseRequestLine(socket)
      requestLine = socket.gets
      puts requestLine
      raise EmptyRequestLineError if requestLine.nil?

      parts = requestLine.strip.split(" ")
      if parts.size < 3 || parts.size > 3
          raise MalformedRequestLineError, "MalformedRequestLineError: expected 3 parts, got #{parts.size}"
      end

      method, target, version = parts

      unless VALID_HTTP_METHODS.include?(method)
          raise InvalidHTTPMethodError, "InvalidHTTPMethodError: #{method}"
      end

      unless version.start_with?("HTTP/1.1")
          raise InvalidHTTPVersionError, "InvalidHTTPVersionError"
      end

      splittedRequestLine = requestLine.split(" ").inspect

      return {
          method: method,
          target: target,
          version: version
      }

      raise "Failed to parse request line: #{e.message}"
  end

  def self.parseHeaders(socket)
      headers = {}
      while (line = socket.gets)
          line = line.strip
          break if line.empty?

          if line.include?(":")
              key, value = line.split(":", 2)
              headers[key.strip.downcase] = value.strip
          end
      end
      return headers
  end

  def self.parseBody(socket, headers)
    content_length = headers["content-length"].to_i
    return nil if content_length == 0
    body = socket.read(content_length)
    return body
  end
end
