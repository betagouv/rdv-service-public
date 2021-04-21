RSpec.describe Admin::InvitationsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "GET #index" do
    context "blank state" do
      it "contains some explanation text" do
        get :index, params: { organisation_id: organisation.id }
        expect(response).to be_successful
        expect(response.body).to include "Aucune invitation en attente"
      end
    end

    context "some invitations exist" do
      let!(:agent1) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:agent_invitee) { create(:agent, :invitation_not_accepted, first_name: nil, last_name: nil, basic_role_in_organisations: [organisation]) }

      it "returns a success response" do
        get :index, params: { organisation_id: organisation.id }
        expect(response).to be_successful
        expect(response.body).not_to include agent1.email
        expect(response.body).to include agent_invitee.email
      end
    end
  end

  describe "POST #reinvite" do
    let(:agent_invitee) { create(:agent, invited_by: agent, confirmed_at: nil, first_name: nil, last_name: nil, basic_role_in_organisations: [organisation]) }

    it "returns a success response" do
      post :reinvite, params: { organisation_id: organisation.id, id: agent_invitee.to_param }
      expect(response).to redirect_to(admin_organisation_invitations_path(organisation))
    end
  end
end
