describe "can see users' RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
  end

  context "with no RDV" do
    before { click_link user.full_name }

    it do
      expect(page).to have_content("À venir\n0 RDV")
      expect(page).to have_content("aucun RDV")
    end
  end

  context "with one RDV" do
    let!(:motif) { create(:motif, organisation: organisation, service: service) }
    let!(:rdv) { create :rdv, :future, users: [user], organisation: organisation, motif: motif, agents: [agent] }

    before { click_link user.full_name }

    it do
      expect(page).to have_content("À venir\n1 RDV")
      click_link "Voir tous les rendez-vous de #{user.full_name}"
      expect_page_title("Liste des RDV")
      expect(page).to have_content("le #{I18n.l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)")
    end
  end
end
