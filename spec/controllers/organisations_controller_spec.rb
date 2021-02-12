describe OrganisationsController, type: :controller do
  describe "#create" do
    it "works" do
      post :create, params: {
        organisation: {
          name: "Ma nouvelle orga",
          departement: "56",
          agent_roles_attributes: [{
            level: "admin",
            agent_attributes: {
              email: "me@myself.hi",
              service_id: "1"
            }
          }]
        }
      }
      expect(response).to be_successful
    end
  end
end
