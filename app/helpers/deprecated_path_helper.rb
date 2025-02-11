module DeprecatedPathHelper
  def stats_path?
    request.path.match(%r{^/stats.*})
  end
end
