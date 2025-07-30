require 'socket'
require 'time'

class InvalidHTTPVersionError < StandardError; end
class InvalidHTTPMethodError < StandardError; end
class MalformedRequestLineError < StandardError; end
class EmptyRequestLineError < StandardError; end

VALID_HTTP_METHODS = %w[GET POST PUT DELETE HEAD OPTIONS PATCH]

def parseRequestLine(socket)
    requestLine = socket.gets
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

def parseHeaders(socket)
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

def parseBody(socket, headers)
  content_length = headers["content-length"].to_i
  return nil if content_length == 0

  body = socket.read(content_length)
  return body
end

def response(socket, statusCode, message, headers)
    response_headers = [
      "HTTP/1.1 #{statusCode.to_s} #{message}",
      "Content-Length: #{message.length}",
    ]
    puts headers.inspect
    if headers["connection"]&.downcase == "close"
      response_headers << headers["connection"]
    end
    body = "\r\n#{message}"
    socket.write(response_headers.join("\r\n") + body)
end

def logRequest(requestLine)
    puts("[#{Time.now.utc.iso8601(3)}] #{requestLine[:method]} #{requestLine[:target]} #{requestLine[:version]}")
end

fakeDB = {
    user: {
        name: "whoo",
        password: ""
    }
}

@routes = {}

def get(target, f)
    @routes[['GET', target]] = f
end

def post(target, f)
    @routes[['POST', target]] = f
end

post("/user", -> (socket, headers) {
    fakeDB[:user][:name] = "fake-user"
    fakeDB[:user][:password] = "fake-password"
    puts headers
    response(socket, 200, fakeDB[:user][:name], headers)
})

get("/test", -> (socket, headers) {
    response(socket, 200, "test", headers)
})

get("/hello", -> (socket, headers) {
    response(socket, 200, "Hello World!", headers)
})

get("/user", -> (socket, headers) {
    user = fakeDB[:user]
    if user == nil
        response(socket, 404, "", headers)
    else
        response(socket, 200, user[:name], headers)
    end
})

def processRequest(socket)
    @headers = {}
    @connection_header = ""
    begin
        requestLine = parseRequestLine(socket)
        logRequest(requestLine)
        @headers = parseHeaders(socket)
        body = parseBody(socket, @headers)

        handler = @routes[[requestLine[:method], requestLine[:target]]]
        if handler
            handler.call(socket, @headers)
        end
    rescue InvalidHTTPVersionError => e
        puts "ProcessRequest => Error: #{e.message}"
        message = "HTTP Version Not Supported"
        statusCode = 505
        response(socket, statusCode, message, @headers)
    rescue InvalidHTTPMethodError => e
        puts "ProcessRequest => Error: #{e.message}"
        message = "Method Not Allowed"
        statusCode = 405
        response(socket, statusCode, message, @headers)
    rescue MalformedRequestLineError => e
        puts "ProcessRequest => Error: #{e.message}"
        message = "Malformed Request Line"
        statusCode = 400
        socket.write("HTTP/1.1 400 #{malformed_request_msg}\r\nContent-Length: #{malformed_request_msg.length}\r\n\r\n#{malformed_request_msg}")
    rescue EmptyRequestLineError => e
        return "break"
    rescue => e
        puts "ProcessRequest => Error: #{e.message}"
        message = "Bad Request"
        statusCode = 400
        response(socket, statusCode, message, @headers)
    end

    @connection_header = @headers["connection"]&.downcase
    if @connection_header == "close"
      return "break"
    end
end

server = TCPServer.new("localhost", 4221)
puts "Listening on port 4221..."

while (client_socket = server.accept)
    Thread.new(client_socket) do |socket|
        loop do
            result = processRequest(socket)
            break if result == "break" 
        end
        socket.close
    end
end
