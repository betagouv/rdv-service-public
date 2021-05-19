# frozen_string_literal: true

RSpec.describe Admin::AgentsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:agent1) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:agent_invitee) { create(:agent, confirmed_at: nil, first_name: nil, last_name: nil, basic_role_in_organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { organisation_id: organisation.id, id: agent1.id } }

    it "destroys the requested agent" do
      subject
      expect(agent1.reload.organisations).not_to include(organisation)
    end

    it "redirects to the invitations list" do
      subject
      expect(response).to redirect_to(admin_organisation_invitations_path(organisation))
    end
  end
end
