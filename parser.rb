module Parser
  VALID_HTTP_METHODS = %w[GET POST PUT DELETE]

  class InvalidHTTPVersionError < StandardError; end
  class InvalidHTTPMethodError < StandardError; end
  class MalformedRequestLineError < StandardError; end
  class EmptyRequestLineError < StandardError; end
  class SocketReadError < StandardError; end
  class TimeoutError < StandardError; end

  def self.parseRequestLine(socket)
      requestLine = socket.gets 
      raise EmptyRequestLineError if requestLine.nil?

      parts = requestLine.strip.split("\r\n").first.split(" ")
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

  def self.parseFixedLengthBody(socket, headers)
    content_length = headers["content-length"].to_i
    return nil if content_length <= 0

    begin
      socket.read_timeout = 5
    rescue NoMethodError
      require 'timeout'
    end

    body = +""
    remaining = content_length
    begin
      Timeout.timeout(5) do
        while remaining > 0
          chunk = socket.readpartial([remaining, 1024].min)
          break if chunk.nil? || chunk.empty?
          body << chunk
          remaining -= chunk.bytesize
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timeout while reading body"
    rescue => e
      raise SocketReadError, "Failed to read request body: #{e.message}"
    end

    return body
  end

  def self.parseChunkedBody(socket, headers)
    begin
      socket.read_timeout = 5
    rescue NoMethodError
      require 'timeout'
    end

    body = +""

    begin
      Timeout.timeout(5) do
        loop do
          line = readLine(socket)
          chunkSize = line.to_i(16)
          break if chunkSize == 0
          
          chunk = socket.read(chunkSize)
          body << chunk
          socket.read(2)
        end

        while (line = readLine(socket)) && !line.strip.empty?
        end
      end
    rescue Timeout::Error
      raise TimeoutError, "Timeout while reading chunked body"
    rescue => e
      raise SocketReadError, "Failed to read chunked body: #{e.message}"

    end

    return body
  end

  def self.readLine(socket)
    line = +""
    while (char = socket.read(1))
      line << char
      break if line.end_with?("\r\n")
    end
    return line
  end

  def self.parseBody(socket, headers)
    if headers["transfer-encoding"]&.downcase == "chunked"
      return parseChunkedBody(socket, headers)
    elsif headers["transfer-encoding"]&.downcase == "content-length"
      return parseFixLengthBody(socket, headers)
    end
    return nil
  end
end
