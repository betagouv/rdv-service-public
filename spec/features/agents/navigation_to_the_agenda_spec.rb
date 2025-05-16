RSpec.describe "Route vers l'agenda" do
  context "when the agent is not signed in" do
    it "redirects to the sign in page" do
      visit "/agents/agenda"

      expect(page).to have_content "Vous devez vous connecter pour continuer"
      expect(page).to have_current_path("/agents/sign_in")
    end
  end

  context "when the agent is signed in" do
    before { login_as(agent, scope: :agent) }

    context "and they don't have any organisation" do
      let(:agent) { create(:agent, basic_role_in_organisations: []) }

      it "shows the page to create a new organisation" do
        visit "/agents/agenda"
        expect(page).to have_content "Vous pouvez demander à ouvrir un espace pour votre organisation"
      end
    end

    context "and they have one organisation" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "shows the agenda for this organisation" do
        visit "/agents/agenda"
        expect(page).to have_content "Votre agenda"
        expect(page).to have_current_path("/admin/organisations/#{organisation.id}/agent_agendas/#{agent.id}")
      end
    end

    context "and they have multiple organisations" do
      let(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation), create(:organisation)]) }

      it "redirections to the list of organisations" do
        visit "/agents/agenda"
        expect(page).to have_content "Choisissez une organisation"
      end
    end
  end
end
