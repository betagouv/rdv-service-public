class LegacyPlanningRedirector
  # @param new_path [Proc]
  def initialize(new_path:)
    @new_path = new_path
  end

  def call(path_params, req)
    # On résout l'URL cible en appelant @new_path avec les path_params
    target_uri = URI.parse(@new_path.call(path_params))
    query_params = Rack::Utils.parse_nested_query(req.query_string)

    # Si on trouve :agent_id dans les params de path, on le copie en querystring
    query_params.merge!({ "agent_id[]" => path_params[:agent_id] }) if path_params[:agent_id].present?

    target_uri.query = query_params.to_query
    target_uri.to_s
  end
end

get "/admin/organisations/:organisation_id/agent_agendas/:agent_id", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/agenda"
}))

get "/admin/organisations/:organisation_id/agents/:agent_id/plage_ouvertures", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/plage_ouvertures"
}))

get "/admin/organisations/:organisation_id/agents/:agent_id/plage_ouvertures/calendar", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/plage_ouvertures/calendar"
}))

get "/admin/organisations/:organisation_id/agents/:agent_id/plage_ouvertures/new", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/plage_ouvertures/new"
}))

get "/admin/organisations/:organisation_id/plage_ouvertures/:plage_ouverture_id/edit", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/plage_ouvertures/#{path_params[:plage_ouverture_id]}/edit"
}))

get "/admin/organisations/:organisation_id/agents/:agent_id/absences", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/absences"
}))

get "/admin/organisations/:organisation_id/agents/:agent_id/absences/new", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/absences/new"
}))

get "/admin/organisations/:organisation_id/absences/:absence_id/edit", to: redirect(LegacyPlanningRedirector.new(new_path: proc { |path_params|
  "/admin/organisations/#{path_params[:organisation_id]}/planning/absences/#{path_params[:absence_id]}/edit"
}))
