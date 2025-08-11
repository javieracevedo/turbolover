# Turbo Lover (HTTP Server) 

Basic HTTP 1/1 Server that accepts TCP connections and serves HTTP Responses.

### Motivation

I'm building this for educational purposes only. Nothing is meant to be optimized or fully complete. 

### Scope

- [x] Listen on a TCP port and accept incoming connections.
- [x] Read and parse the HTTP request line into method, path, and version.
- [x] Parse request headers into a key/value map.
- [x] Accept Accept-Encoding header and respond with Content-Enconding header (Only accepts gzip as valid encoding)
- [x] Only accepts Content-Type header as `text/plain`, `application/json`, and `application/octet-stream` (only in response)
- [x] Send well-formed HTTP responses, including status line, headers, and body.
- [x] Expose a simple callback/handler interface such that the server calls something like: `onRequest({ method, path, headers, rawBody }, respond)`.
- [x] Graceful error handling for malformed requests.
    - [x] 400 Bad Request (Parsing Errors: request line, headers, body | Content-Length header is invalid) 
    - [x] 505 Unsupported Version (HTTP Version Not Supported)
- [x] Read the raw request body (as bytes / Buffer / string) according to headers like Content-Length and Transfer-Encoding: chunked.
- [x] Improve the logger module and use it in place of regular puts calls.
- [x] Test suite for all the cases above.
- [ ] Package the server so it can be used as a library.
