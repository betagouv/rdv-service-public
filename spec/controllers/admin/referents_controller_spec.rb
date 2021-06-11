# frozen_string_literal: true

describe Admin::ReferentsController, type: :controller do
  describe "#new" do
    it "assigns available agents and respond success" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      service = create(:service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      lea = create(:agent, basic_role_in_organisations: [organisation], service: service)
      create(:agent, basic_role_in_organisations: [create(:organisation)])
      sign_in agent

      get :new, params: { organisation_id: organisation.id, user_id: user.id }

      expect(response).to be_successful
      expect(assigns(:available_agents)).to eq([agent, lea])
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
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user))
    end

    it "return errors and render new" do
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

      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("problème")
    end
  end

  describe "#update" do
    it "update user's agent_ids reference and redirect to user's page" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      agent = create(:agent, basic_role_in_organisations: [organisation])
      lea = create(:agent, basic_role_in_organisations: [organisation])
      stef = create(:agent, basic_role_in_organisations: [organisation])
      expect(agent.organisations).to eq([organisation])
      sign_in agent

      post :update, params: { organisation_id: organisation.id, user_id: user.id, user: { agent_ids: [lea.id, stef.id] } }

      expect(user.reload.agents.sort).to eq([lea, stef].sort)
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user))
    end

    it "with a bad agent_id only, delete agents and return to user's page" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      lea = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, agents: [lea], organisations: [organisation])
      sign_in agent

      post :update, params: { organisation_id: organisation.id, user_id: user.id, user: { agent_ids: ["bad agent id"] } }

      expect(user.reload.agents).to eq([])
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user))
    end

    it "when update failed return to user's page with an error message" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      lea = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, agents: [lea], organisations: [organisation])
      sign_in agent

      allow_any_instance_of(User).to receive(:update).and_return(false)

      post :update, params: { organisation_id: organisation.id, user_id: user.id, user: { agent_ids: ["bad agent id"] } }

      expect(flash[:error]).to eq("Erreur lors de la modification des référents")
      expect(user.reload.agents).to eq([lea])
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user))
    end
  end
end
