# config/initializers/routing_draw.rb

# Adds draw method into Rails routing
# It allows us to keep routing splitted into files
class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(Rails.root.join("config/routes/#{routes_name}.rb").read)
  end
end
