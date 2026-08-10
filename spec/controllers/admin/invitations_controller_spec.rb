RSpec.describe Admin::InvitationsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "POST #reinvite" do
    let(:agent_invitee) { create(:agent, invited_by: agent, confirmed_at: nil, first_name: nil, last_name: nil, allow_blank_name: true, basic_role_in_organisations: [organisation]) }

    before do
      allow(UnblockBrevoTransactionalContact).to receive(:new).and_return(instance_double(UnblockBrevoTransactionalContact, call: true))
    end

    it "returns a success response" do
      post :reinvite, params: { organisation_id: organisation.id, id: agent_invitee.to_param }
      expect(response).to redirect_to(admin_organisation_agents_path(organisation))
    end
  end
end
