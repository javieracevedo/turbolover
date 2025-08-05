module HttpHandler
  require_relative "parser"
  require_relative "router"

  def self.response(socket, statusCode, message, headers, body)
      response_headers = [
        "HTTP/1.1 #{statusCode.to_s} #{message}",
        "Content-Length: #{body.length}",
      ]
     
      if headers["connection"] == "close"
        response_headers << "Connection: close"
      else
        response_headers << "Connection: keep-alive"
      end

      valid_content_types = %w[text/plain, application/json, application/octet-stream]
      if headers["content-type"] && valid_content_types.include?(headers["content-type"])
        response_headers << "Content-Type: #{headers["content-type"]}"
      end

      if headers["accept-encoding"] == "gzip"
        response_headers << "Content-Encoding: #{headers["accept-encoding"]}"
      end

      body = "\r\n\r\n#{body}"
     
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
          handler, data = Router.match(requestLine[:method], requestLine[:target])  
          if handler
            handler.call(socket, @headers, data, body)
          else
            puts "ProcessRequest => Error: 404 Not Found"
            message = "Not Found"
            statusCode = 404
            response(socket, statusCode, message, @headers, "")
            return "break"
          end
      rescue Parser::InvalidHTTPVersionError => e
          puts "ProcessRequest => Error: #{e.message}"
          message = "HTTP Version Not Supported"
          statusCode = 505
          response(socket, statusCode, message, @headers, "")
          return "break"
      rescue Parser::InvalidHTTPMethodError => e
          puts "ProcessRequest => Error: #{e.message}"
          message = "Method Not Allowed"
          statusCode = 405
          response(socket, statusCode, message, @headers, "")
          return "break"
      rescue Parser::MalformedRequestLineError => e
          puts "ProcessRequest => Error: #{e.message}"
          message = "Malformed Request Line"
          statusCode = 400
          socket.write("HTTP/1.1 400 #{message}\r\nContent-Length: #{malformed_request_msg.length}\r\n\r\n#{malformed_request_msg}") rescue EmptyRequestLineError => e
          return "break"
      rescue => e
          puts e
          puts "ProcessRequest => Error: #{e.message}"
          message = "Bad Request"
          statusCode = 400
          response(socket, statusCode, message, @headers, "")
          return "break"
      end

      @connection_header = @headers["connection"]
      if @connection_header == "close"
        return "break"
      end
  end
end
