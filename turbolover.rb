require 'socket'
require 'time'
require 'zlib'
require 'stringio'
require_relative 'parser'
require_relative 'logger'
require_relative 'http_handler'

class TurboLover
  def initialize(host, port, onRequest)
    self.initTCPServer(host, port) 
    @onRequest = onRequest
  end

  def initTCPServer(host, port)
    @server = TCPServer.new(host, 4221)
    Logger.message("Listening on port #{port}") 
  end

  def run()
    while (client_socket = @server.accept)
      Thread.new(client_socket) do |socket|
        loop do
          result = HttpHandler.processRequest(socket, @onRequest)
          break if result == "break"
        end
        socket.close
      end
    end
  end
end

onRequest = -> (socket, requestData, response) {
  response.call(socket, 200, "OK", requestData[:headers], requestData[:body])
}

server = TurboLover.new("localhost", 4221, onRequest)
server.run()

