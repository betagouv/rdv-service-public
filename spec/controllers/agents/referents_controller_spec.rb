describe Agents::ReferentsController, type: :controller do
  describe "#update" do
    it "update user's agent_ids reference and redirect to user's page" do
      organisation = create(:organisation)
      user = create(:user, agents: [], organisations: [organisation])
      agent = create(:agent, organisations: [organisation])
      lea = create(:agent, organisations: [organisation])
      stef = create(:agent, organisations: [organisation])
      expect(agent.organisations).to eq([organisation])
      sign_in agent

      post :update, params: { organisation_id: organisation.id, user_id: user.id, user: { agent_ids: [lea.id, stef.id] } }

      expect(user.reload.agents.sort).to eq([lea, stef].sort)
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user))
    end

    it "with a bad agent_id only, delete agents and return to user's page" do
      organisation = create(:organisation)
      agent = create(:agent, organisations: [organisation])
      lea = create(:agent, organisations: [organisation])
      user = create(:user, agents: [lea], organisations: [organisation])
      sign_in agent

      post :update, params: { organisation_id: organisation.id, user_id: user.id, user: { agent_ids: ["bad agent id"] } }

      expect(user.reload.agents).to eq([])
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user))
    end

    it "when update failed return to user's page with an error message" do
      organisation = create(:organisation)
      agent = create(:agent, organisations: [organisation])
      lea = create(:agent, organisations: [organisation])
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
