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
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user, anchor: "agents-referents"))
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

  describe "#delete" do
    it "remove given agent from user's referents " do
      organisation = create(:organisation)
      service = create(:service)
      referent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
      user = create(:user, agents: [referent], organisations: [organisation])

      sign_in agent

      post :destroy, params: { organisation_id: organisation.id, user_id: user.id, agent_id: referent.id }

      expect(user.reload.agents).not_to include(referent)
      expect(response).to redirect_to(admin_organisation_user_path(organisation, user, anchor: "agents-referents"))
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

      post :destroy, params: { organisation_id: organisation.id, user_id: user.id, agent_id: referent.id }

      expect(response).to redirect_to(admin_organisation_user_path(organisation, user, anchor: "agents-referents"))
      expect(flash[:error]).to eq("problème")
    end
  end
end
