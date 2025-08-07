require 'socket'
require 'time'
require 'zlib'
require 'stringio'
require_relative 'parser'
require_relative 'logger'
require_relative 'http_handler'


server = TCPServer.new("localhost", 4221)
Logger.message("Listening on port 4221\n")

onRequest = -> (socket, requestData, response) {
  response.call(socket, 200, "OK", requestData[:headers], requestData[:body])
}

while (client_socket = server.accept)
    Thread.new(client_socket) do |socket|
        loop do
            result = HttpHandler.processRequest(socket, onRequest)
            break if result == "break" 
        end
        socket.close
    end
end

