# frozen_string_literal: true

RSpec.describe Admin::Territories::InvitationsDeviseController, type: :controller do
  render_views

  describe "GET #new" do
    context "for a cnfs" do
      it "only allows inviting agents for the secretariat" do
        create(:service, name: "Secrétariat")
        territory = create(:territory)
        request.env["devise.mapping"] = Devise.mappings[:agent]
        agent = create(:agent, invitation_accepted_at: nil, service: create(:service, name: "Conseiller Numérique"))
        create(:agent_territorial_access_right, territory: territory, agent: agent)
        sign_in agent
        get :new, params: { territory_id: territory.id }
        expect(response).not_to have_content("Admin")
        Devise.mailer.deliveries.clear
      end
    end
  end
end
