# frozen_string_literal: true

module DeprecatedPathHelper
  def agent_path?
    request.path =~ /(agents|admin)/ || (request.path == "/" && current_agent.present?)
  end

  def stats_path?
    request.path.match(%r{^/stats.*})
  end
end
