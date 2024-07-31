RSpec.describe Admin::Territories::InvitationsDeviseController, type: :controller do
  render_views
  let(:service) { create(:service, name: "Secrétariat") }
  let(:territory) { create(:territory) }

  describe "GET #new" do
    context "for a cnfs" do
      it "only allows inviting agents for the secretariat" do
        request.env["devise.mapping"] = Devise.mappings[:agent]
        agent = create(:agent, invitation_accepted_at: nil, service: create(:service, :conseiller_numerique))
        create(:agent_territorial_access_right, territory: territory, agent: agent)
        sign_in agent
        get :new, params: { territory_id: territory.id }
        expect(response).not_to have_content("Admin")
        Devise.mailer.deliveries.clear
      end
    end
  end

  describe "POST create" do
    describe "initialize access rights for invited agent" do
      let(:agent) { create(:agent, service: service, organisations: [organisation], role_in_territories: [territory]) }
      let(:organisation) { create(:organisation, territory: territory) }

      before do
        create(:agent_territorial_access_right, agent: agent, allow_to_manage_access_rights: true, allow_to_invite_agents: true)
        sign_in agent
        request.env["devise.mapping"] = Devise.mappings[:agent]
      end

      it "creates new access rights with none exist" do
        params = { territory_id: territory.id,
                   admin_agent: {
                     email: "hacker@renard.com",
                     service_ids: [service.id],
                   }, }
        expect do
          post :create, params: params
        end.to change(AgentTerritorialAccessRight, :count)
      end

      it "do nothing if already exist for this territory" do
        other_organisation_on_same_territory = create(:organisation, territory: organisation.territory)
        existing_agent = create(:agent, organisations: [other_organisation_on_same_territory], email: "hacker@renard.com")
        create(:agent_territorial_access_right, agent: existing_agent, territory: organisation.territory)

        params = { territory_id: territory.id,
                   admin_agent: {
                     email: "hacker@renard.com",
                     service_id: service.id,
                   }, }

        expect do
          post :create, params: params
        end.not_to change(AgentTerritorialAccessRight, :count)
      end

      describe "when trying to invite an agent to an organisation I don't control" do
        let(:organisation_in_other_territory) { create(:organisation) }

        it "doesn't work" do
          post :create, params: {
            territory_id: territory.id,
            admin_agent: {
              email: "hacker@renard.com",
              service_ids: [service.id],
              organisation_ids: [organisation_in_other_territory.id],
            },
          }

          expect(organisation_in_other_territory.reload.agents).to be_empty
        end
      end
    end
  end
end
