require 'socket'
require 'time'
require_relative 'parser'
require_relative 'router'
require_relative 'db'
require_relative 'logger'
require_relative 'http_handler'

server = TCPServer.new("localhost", 4221)
puts "Listening on port 4221..."

Router.get("/test", -> (socket, headers, data) {
    HttpHandler.response(socket, 200, "test", headers, "test")
})

Router.get("/hello", -> (socket, headers, data) {
    HttpHandler.response(socket, 200, "Hello World!", headers, "Hello World!")
})

Router.get("/user", -> (socket, headers, data) {
  user = Db.fakeDB[:user]
  if user == nil
      HttpHandler.response(socket, 404, "", headers, "")
  else
      HttpHandler.response(socket, 200, user[:name], headers, user[:name])
  end
})

Router.get("/", -> (socket, headers, data) {
  HttpHandler.response(socket, 200, "OK", headers, "") 
})

Router.post("/user", -> (socket, headers, data) {
  Db.fakeDB[:user][:name] = "fake-user"
  Db.fakeDB[:user][:password] = "fake-password"
  HttpHandler.response(socket, 200, Db.fakeDB[:user][:name], headers, Db.fakeDB[:user][:name])
})

Router.get("/echo/*", -> (socket, headers, data) {
  headers["content-type"] = "text/plain"
  HttpHandler.response(socket, 200, "OK", headers, data)
})

while (client_socket = server.accept)
    Thread.new(client_socket) do |socket|
        loop do
            result = HttpHandler.processRequest(socket)
            break if result == "break" 
        end
        socket.close
    end
end

