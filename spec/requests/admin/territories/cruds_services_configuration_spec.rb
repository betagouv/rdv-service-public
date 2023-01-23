# frozen_string_literal: true

describe "CRUD services configuration", type: :request do
  include Rails.application.routes.url_helpers

  describe "GET admin/territories/:territory_id/services" do
    it "returns all services" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_role, agent: agent, territory: territory)

      sign_in agent

      services = create_list(:service, 3)

      get admin_territory_services_path(territory)

      expect(response).to be_successful
    end
  end

  describe "#new" do
    it "shown new service form" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_role, agent: agent, territory: territory)
      

      sign_in agent

      get new_admin_territory_service_path(territory)

      expect(response).to be_successful
    end
  end

  describe "#create" do
    it "creates new service" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_role, agent: agent, territory: territory)

      sign_in agent

      service = create(:service)

      expect do
        post admin_territory_services_path(territory), params: { service: {name: "nouveau service", short_name: "nouveau"}}

        expect(response).to redirect_to(admin_territory_services_path)
      end.to change(Service, :count).by(1)
      expect(Service.last.name).to eq("nouveau service")

    end
  end

  describe "#edit" do
    it "shown edit service form" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_role, agent: agent, territory: territory)

      sign_in agent

      service = create(:service)

      get edit_admin_territory_service_path(territory, service)

      expect(response).to be_successful
    end
  end

  describe "#update" do
    it "update a service" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_role, agent: agent, territory: territory)

      sign_in agent

      service = create(:service, name: "bidule truc")

      put admin_territory_service_path(territory, service), params: { service: {name: "nouveau service" }}

      expect(response).to redirect_to(admin_territory_services_path)
      expect(service.reload.name).to eq "nouveau service"
    end
  end

  describe "#destroy" do
    it "update a service" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_role, agent: agent, territory: territory)

      sign_in agent

      service = create(:service)

      expect do
        delete admin_territory_service_path(territory, service)

        expect(response).to redirect_to(admin_territory_services_path)
      end.to change{Service.count}.by(-1)
    end
  end
end
