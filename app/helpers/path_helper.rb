module PathHelper
  def root_path?
    request.path == root_path
  end

  def stats_rdv_path(status)
    case controller_name
    when "stats"
      if params[:agent_id].present?
        admin_organisation_agent_rdvs_path(current_organisation, params[:agent_id], status: status, default_period: true)
      else
        admin_organisation_rdvs_path(current_organisation, status: status, default_period: true)
      end
    when "users", "relatives"
      admin_organisation_user_rdvs_path(current_organisation, params[:id], status: status)
    end
  end

  def agent_path?
    request.path =~ /(agents|admin)/ || (request.path == "/" && current_agent.present?)
  end

  def stats_path?
    request.path.match(%r{^/stats.*})
  end
end
