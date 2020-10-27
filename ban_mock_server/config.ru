require "json"

class Application
  def call(env)
    status  = 200
    headers = {
      "Content-Type" => "application/json",
      "Cross-Origin-Resource-Policy" => "cross-site"
    }
    body = JSON.dump({})

    if env["PATH_INFO"] == "/search/"
      params = Rack::Utils.parse_nested_query(env["QUERY_STRING"])
      path = File.join(File.dirname(__FILE__), "#{params['q']}.json")
      body = [IO.read(path)] if File.file?(path)
    end
    [status, headers, body]
  end
end

run Application.new
