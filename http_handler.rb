module HttpHandler
  require_relative "parser"

  def self.response(socket, statusCode, message, headers, body)
    response_headers = [
      "HTTP/1.1 #{statusCode.to_s} #{message}"
    ]

    if body
      response_headers << "Content-Length: #{body.length}"
    end
    
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

  def self.processRequest(socket, onRequest) 
    @headers = {}
    @connection_header = ""
    begin
      requestLine = Parser.parseRequestLine(socket)
      Logger.request(requestLine)
      @headers = Parser.parseHeaders(socket)
      body = Parser.parseBody(socket, @headers)
      requestData = {
        requestLine: requestLine,
        headers: @headers,
        body: body
      }

      response_proc = method(:response).to_proc
      onRequest.call(socket, requestData, response_proc)
    rescue Parser::InvalidHTTPVersionError => e
      Logger.error("ProcessRequest => Invalid HTTP Version Error: #{e.message}")
      message = "HTTP Version Not Supported"
      statusCode = 505
      response(socket, statusCode, message, @headers, "")
      return "break"
    rescue Parser::InvalidHTTPMethodError => e
      Logger.error("ProcessRequest => Invalid HTTP Method Error: #{e.message}")
      message = "Method Not Allowed"
      statusCode = 405
      response(socket, statusCode, message, @headers, "")
      return "break"
    rescue Parser::MalformedRequestLineError => e
      Logger.error("ProcessRequest => Malformed Request Line Error: #{e.message}")
      message = "Malformed Request Line"
      statusCode = 400
      socket.write("HTTP/1.1 #{statusCode} Bad Request\r\nContent-Length: #{message.length}\r\n\r\n#{message}") 
      return "break"
    rescue Parser::EmptyRequestLineError => e
      return "break"
    rescue Parser::TimeoutError => e
      Logger.error("ProcessRequest => Timeout Error: #{e.message}")
      message = "Request Timeout"
      statusCode = 408
      response(socket, statusCode, message, @headers, message)
      return "break"
    rescue Parser::SocketReadError => e
      Logger.error("ProcessRequest => Socket Read Error: #{e.message}")
      message = "Internal Server Error"
      statusCode = 500 
      response(socket, statusCode, message, @headers, e.message)
      return "break"
    rescue => e
      Logger.error("ProcessRequest => Error: #{e.message}")
      message = "Internal Server Error"
      statusCode = 500
      response(socket, statusCode, message, @headers, "")
      return "break"
    end

    @connection_header = @headers["connection"]
    if @connection_header == "close"
      return "break"
    end
  end
end

