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
          post :create, params
        end.to change { Organisation.count }.by(1)
      end.to change { Agent.count }.by(1)
      expect(response).to be_successful
    end

    it "redirect_to :new when organisation create error" do
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

      post :create, params
      expect(response).to redirect_to(new_organisation_path)
    end

    it "return errors with an existing organisation for same departement" do
      organisation = create(:organisation, departement: 56)
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

      post :create, params
      expect(response).to redirect_to(new_organisation_path)
      expect(flash[:error]).to eq("Au moins une organisation, avec au moins un agent existe déjà pour ce département. Merci de prendre contact avec cette personnes pour ajouter d'autres organisations à ce département")
    end
  end
end
