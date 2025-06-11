get "/admin/organisations/:organisation_id/agent_agendas/:agent_id", to: (redirect do |path_params, req|
  uri = URI.parse("admin/organisations/#{path_params[:organisation_id]}/planning/agenda")
  original_params = Rack::Utils.parse_nested_query(req.query_string)
  merged_params = original_params.merge({ 'agent_id[]' => path_params[:agent_id] })
  uri.query = merged_params.to_query
  uri.to_s
end)
