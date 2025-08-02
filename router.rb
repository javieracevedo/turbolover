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
    puts "BLAH " + target_first_resource
    match = @routes.find do |(method, path), _handler|
      path.start_with?(target_first_resource)
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
