describe OrganisationsController, type: :controller do
  describe "#create" do
    it "responds succesfully, creates organisation, agent and roles" do
      service = create(:service)
      params = {
        params: {
          organisation: {
            name: "Ma nouvelle orga",
            territory_attributes: {
              departement_number: "56"
            },
            agent_roles_attributes: [{
              level: "admin",
              agent_attributes: {
                email: "me@myself.hi",
                service_id: service.id
              }
            }]
          }
        }
      }

      expect(Territory.count).to eq 0
      expect(Organisation.count).to eq 0
      expect(Agent.count).to eq 0
      post :create, params: params
      expect(response).to be_successful
      expect(Territory.count).to eq 1
      expect(Organisation.count).to eq 1
      expect(Agent.count).to eq 1
      agent = Agent.first
      expect(agent.roles.count).to eq 1
      expect(agent.territorial_roles.count).to eq 1
    end

    it "renders :new when there is an error upon creation" do
      params = {
        params: {
          organisation: {
            name: "Ma nouvelle orga",
            territory_attributes: {
              departement_number: "56"
            },
            agent_roles_attributes: [{
              level: "admin",
              agent_attributes: {
                email: "me@myself.hi",
                service_id: "unknow" # this is the error
              }
            }]
          }
        }
      }

      post :create, params: params
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end
  end
end
