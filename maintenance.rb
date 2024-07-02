# app.rb
require "rack"

class SimpleRackApp
  def read_file
    puts "reading file maintenance.html..."
    File.read(File.join(Dir.pwd, "public", "maintenance.html"))
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.get_header("HTTP_ACCEPT")&.include?("text/html")
      @content ||= read_file
      [200, { "Content-Type" => "text/html" }, [@content]]
    else
      [404, {}, []]
    end
  end
end

Rack::Handler::WEBrick.run SimpleRackApp.new, Port: ENV["PORT"] || 3000
