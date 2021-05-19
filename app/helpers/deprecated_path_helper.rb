# frozen_string_literal: true

module DeprecatedPathHelper
  def root_path?
    request.path == root_path
  end

  def user_path?(user)
    request.path == admin_organisation_user_path(current_organisation, user)
  end

  def agent_path?
    request.path =~ /(agents|admin)/ || (request.path == "/" && current_agent.present?)
  end

  def stats_path?
    request.path.match(%r{^/stats.*})
  end
end
