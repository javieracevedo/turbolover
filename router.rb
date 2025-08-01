module Router
  @routes = {}

  def self.get(target, f)
    @routes[['GET', target]] = f
  end

  def self.post(target, f)
    @routes[['POST', target]] = f
  end

  def self.routes
    @routes
  end
end
