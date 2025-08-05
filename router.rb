module Router
  @routes = {}

  def self.get(target, f)
    @routes[['GET', target]] = f
  end

  def self.post(target, f)
    @routes[['POST', target]] = f
  end

  def self.match(method, target)
    # try to match the route literally
    handler = @routes[[method, target]]
    puts handler
    if handler
      return handler, ""
    end 
  
    # try to match wildcard route
    puts target.strip.split("/").inspect
    target_first_resource = "\/#{target.split("/")[1]}" 
    target_last_resource = target.split("/").last 
    match = @routes.find do |(route_method, path), _handler|
      path.start_with?(target_first_resource) and route_method == method 
    end 

    if match
      handler = match[1]
      return handler, target_last_resource 
    end
  end

  def self.routes
    @routes
  end
end
