# frozen_string_literal: true

describe Admin::StatsController, type: :controller do
  describe "#rdvs" do
    it "returns sucess" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      sign_in agent
      get :rdvs, params: { organisation_id: organisation.id, agent_id: agent.id, format: :json }
      expect(response).to be_successful
    end
  end
end
