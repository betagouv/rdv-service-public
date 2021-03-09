describe OrganisationsController, type: :controller do
  describe "#create" do
    it "respond successfull, create organisation and create agent" do
      service = create(:service)
      params = {
        params: {
          organisation: {
            name: "Ma nouvelle orga",
            departement: "56",
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

      expect do
        expect do
          post :create, params: params
        end.to change { Organisation.count }.by(1)
      end.to change { Agent.count }.by(1)
      expect(response).to be_successful
    end

    it "render :new when organisation create error" do
      params = {
        params: {
          organisation: {
            name: "Ma nouvelle orga",
            departement: "56",
            agent_roles_attributes: [{
              level: "admin",
              agent_attributes: {
                email: "me@myself.hi",
                service_id: "unknow"
              }
            }]
          }
        }
      }

      post :create, params: params
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end

    it "return errors with an existing organisation for same departement" do
      create(:organisation, departement: 56)
      service = create(:service)
      params = {
        params: {
          organisation: {
            name: "Ma nouvelle orga",
            departement: "56",
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

      post :create, params: params
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end
  end
end
