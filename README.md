# Turbo Lover (HTTP Server) 

Basic HTTP Server that accepts TCP connections and serves HTTP Responses.

### Motivation

I'm building this for educational purposes only. Nothing is meant to be optimized or fully complete. 

### Scope

- [ ] Listen on a TCP port and accept incoming connections.
- [ ] Read and parse the HTTP request line into method, path, and version.
- [ ] Parse request headers into a key/value map.
- [ ] Read the raw request body (as bytes / Buffer / string) according to headers like Content-Length and Transfer-Encoding: chunked.
- [ ] Expose a simple callback/handler interface such that the server calls something like: `onRequest({ method, path, headers, rawBody }, respond)`
- [ ] Send well-formed HTTP responses, including status line, headers, and body.
- [ ] Graceful error handling for malformed requests (return 400) and internal errors (500).

