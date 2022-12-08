# frozen_string_literal: true

describe Admin::ReferentAssignationsController, type: :controller do
  describe "#index" do
    it "assigns available agents and respond success" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      service = create(:service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      lea = create(:agent, basic_role_in_organisations: [organisation], service: service)
      create(:agent, basic_role_in_organisations: [create(:organisation)])
      sign_in agent

      get :index, params: { organisation_id: organisation.id, user_id: user.id }

      expect(response).to be_successful
      expect(assigns(:agents).sort).to eq([agent, lea].sort)
      expect(assigns(:referents)).to eq([])
    end

    it "assigns matching search agent" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      service = create(:service)
      connected_agent = create(:agent, basic_role_in_organisations: [organisation], service: service, first_name: "Marc", last_name: "Dubois")
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service, first_name: "Martine", last_name: "Durant")
      create(:agent, basic_role_in_organisations: [organisation], service: service, first_name: "Jean", last_name: "Dupont")
      sign_in connected_agent

      get :index, params: { organisation_id: organisation.id, user_id: user.id, search: "Mart" }

      expect(response).to be_successful
      expect(assigns(:agents)).to eq([agent])
      expect(assigns(:referents)).to eq([])
    end
  end

  describe "#create" do
    it "add given agent to referents and redirect to user show" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      service = create(:service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      new_referent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      sign_in agent

      post :create, params: { organisation_id: organisation.id, user_id: user.id, agent_id: new_referent.id }

      expect(user.reload.agents).to include(new_referent)
      expect(response).to redirect_to(admin_organisation_user_referent_assignations_path(organisation, user))
    end

    it "return errors and redirect to index" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      service = create(:service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      new_referent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      sign_in agent

      allow_any_instance_of(User).to receive(:save).and_return(false)
      allow_any_instance_of(User).to receive(:errors)
        .and_return(OpenStruct.new(full_messages: ["problème"]))

      post :create, params: { organisation_id: organisation.id, user_id: user.id, agent_id: new_referent.id }

      expect(response).to redirect_to(admin_organisation_user_referent_assignations_path(organisation, user))
      expect(flash[:error]).to eq("problème")
    end
  end

  describe "#delete" do
    it "remove given agent from user's referents" do
      organisation = create(:organisation)
      service = create(:service)
      referent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      user = create(:user, agents: [referent], organisations: [organisation])

      sign_in agent

      post :destroy, params: { organisation_id: organisation.id, user_id: user.id, id: referent.id }

      expect(user.reload.agents).not_to include(referent)
      expect(response).to redirect_to(admin_organisation_user_referent_assignations_path(organisation, user))
    end

    it "return errors and redirect to user's show" do
      organisation = create(:organisation)
      service = create(:service)
      referent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      user = create(:user, agents: [referent], organisations: [organisation])

      sign_in agent

      allow_any_instance_of(User).to receive(:save).and_return(false)
      allow_any_instance_of(User).to receive(:errors)
        .and_return(OpenStruct.new(full_messages: ["problème"]))

      post :destroy, params: { organisation_id: organisation.id, user_id: user.id, id: referent.id }

      expect(response).to redirect_to(admin_organisation_user_referent_assignations_path(organisation, user))
      expect(flash[:error]).to eq("problème")
    end
  end
end
