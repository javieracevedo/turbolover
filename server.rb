require 'socket'
require 'time'
require 'zlib'
require 'stringio'
require_relative 'parser'
require_relative 'router'
require_relative 'db'
require_relative 'logger'
require_relative 'http_handler'

directory = nil

def gzip_string(string)
  buffer = StringIO.new
  gz = Zlib::GzipWriter.new(buffer)
  gz.write(string)
  gz.close
  buffer.string
end

ARGV.each_with_index do |arg, i|
  if arg == "--directory" && ARGV[i + 1]
    directory = ARGV[i + 1]
  end
end

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

Router.get("/", -> (socket, headers, data, body="") {
  HttpHandler.response(socket, 200, "OK", headers, "") 
})

Router.post("/user", -> (socket, headers, data, body="") {
  Db.fakeDB[:user][:name] = "fake-user"
  Db.fakeDB[:user][:password] = "fake-password"
  HttpHandler.response(socket, 200, Db.fakeDB[:user][:name], headers, Db.fakeDB[:user][:name])
})

Router.get("/echo/*", -> (socket, headers, data, body="") {
  headers["content-type"] = "text/plain"
  if headers["accept-encoding"] == 'gzip'
    data = gzip_string(data)
  end
  HttpHandler.response(socket, 200, "OK", headers, data)
})

Router.get("/user-agent", -> (socket, headers, data, body="") {
  headers["content-type"] = "text/plain"
  HttpHandler.response(socket, 200, "OK", headers, headers["user-agent"])
})

Router.get("/files/*", -> (socket, headers, data, body="") {
  headers["content-type"] = "application/octet-stream"
  
  begin 
    content = File.read(directory + data)
    HttpHandler.response(socket, 200, "OK", headers, content)
  rescue => e
    HttpHandler.response(socket, 404, "Not Found", headers, "")
  end
})

Router.post("/files/*", -> (socket, headers, data, body="") {
  mode = File::WRONLY | File::CREAT
  
  file = File.open(directory + data, mode)
  file.write(body)
  file.close()

  HttpHandler.response(socket, 201, "Created", headers, "")
})

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

