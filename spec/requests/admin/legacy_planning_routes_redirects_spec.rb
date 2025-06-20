RSpec.describe "legacy planning routes redirect" do
  it "redirects agent_agendas#show" do
    get "/admin/organisations/1234/agent_agendas/5678?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/agenda?agent_id%5B%5D=5678&my_param=my_value")
  end

  it "redirects plage_ouvertures#index" do
    get "/admin/organisations/1234/agents/5678/plage_ouvertures?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/plage_ouvertures?agent_id%5B%5D=5678&my_param=my_value")
  end

  it "redirects plage_ouvertures#calendar" do
    get "/admin/organisations/1234/agents/5678/plage_ouvertures/calendar?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/plage_ouvertures/calendar?agent_id%5B%5D=5678&my_param=my_value")
  end

  it "redirects plage_ouvertures#new" do
    get "/admin/organisations/1234/agents/5678/plage_ouvertures/new?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/plage_ouvertures/new?agent_id%5B%5D=5678&my_param=my_value")
  end

  it "redirects plage_ouvertures#edit" do
    get "/admin/organisations/1234/plage_ouvertures/7777/edit?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/plage_ouvertures/7777/edit?my_param=my_value")
  end

  it "redirects absences#index" do
    get "/admin/organisations/1234/agents/5678/absences?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/absences?agent_id%5B%5D=5678&my_param=my_value")
  end

  it "redirects absences#new" do
    get "/admin/organisations/1234/agents/5678/absences/new?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/absences/new?agent_id%5B%5D=5678&my_param=my_value")
  end

  it "redirects absences#edit" do
    get "/admin/organisations/1234/absences/7777/edit?my_param=my_value"
    expect(response).to redirect_to("/admin/organisations/1234/planning/absences/7777/edit?my_param=my_value")
  end
end
