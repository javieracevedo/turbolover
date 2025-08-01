module HttpHandler
  require_relative "parser"
  require_relative "router"

  def self.response(socket, statusCode, message, headers)
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

  def self.processRequest(socket) 
      @headers = {}
      @connection_header = ""
      begin
          requestLine = Parser.parseRequestLine(socket)
          Logger.logRequest(requestLine)
          @headers = Parser.parseHeaders(socket)
          body = Parser.parseBody(socket, @headers)

          handler = Router.routes[[requestLine[:method], requestLine[:target]]]
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
          socket.write("HTTP/1.1 400 #{malformed_request_msg}\r\nContent-Length: #{malformed_request_msg.length}\r\n\r\n#{malformed_request_msg}") rescue EmptyRequestLineError => e
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
end
