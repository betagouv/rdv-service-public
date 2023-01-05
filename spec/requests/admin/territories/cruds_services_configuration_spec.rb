# frozen_string_literal: true

describe Admin::Territories::ServicesController, type: :controller do

  describe "GET admin/territories/:territory_id/services" do
		it "retruns all services" do
			territory = create(:territory)
			agent = create(:agent)
			create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

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
			create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

			sign_in agent

			get new_admin_territory_services_path(territory)

			expect(response).to be_successful
		end
	end	

	describe "#create" do
		it "creates new service" do
			territory = create(:territory)
			agent = create(:agent)
			create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

			sign_in agent

			expect do 
				post admin_territory_services_path(territory), params: {name: "nouveau service"}

				expect(response).to redirect_to(admin_territory_services_path)
				expect(Service.last.name).to eq("nouveau service")
			end.to change {service.count}.by(1)
		end
	end

	describe "#edit" do
		it "shown edit service form" do
			territory = create(:territory)
			agent = create(:agent)
			create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

			sign_in agent

			service = create(:service)

			get new_admin_territory_services_path(territory, service)

			expect(response).to be_successful
		end
	end

	describe "#update" do
		it "update a service" do
			territory = create(:territory)
			agent = create(:agent)
			create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

			sign_in agent
			
			service = create(:service, name: "bidule truc")

			put admin_territory_services_path(territory, service), params: {name: "nouveau service"}

			expect(response).to redirect_to(admin_territory_services_path)
			expect(service.reload.name).to eq "nouveau service"
		end
	end

	describe "#destroy" do
    it "update a service" do
			territory = create(:territory)
			agent = create(:agent)
			create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

			sign_in agent
			
			service = create(:service)
			put admin_territory_services_path(territory, service)

			
			expect do
				put admin_territory_services_path(territory, service)

				expect(response).to redirect_to(admin_territory_services_path)
			end.to change(Service.count).by(-1)
		end
	end
  

  
end