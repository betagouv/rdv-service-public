# frozen_string_literal: true

describe "can see users' RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, first_name: "Tanguy", last_name: "Laverdure", organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
  end

  context "with no RDV" do
    before do
      visit admin_organisation_user_path(organisation, user)
    end

    it do
      expect(page).to have_content("À venir\n0 RDV")
      expect(page).to have_content("aucun RDV")
    end
  end

  context "with one RDV" do
    let!(:motif) { create(:motif, organisation: organisation, service: service) }
    let!(:rdv) { create :rdv, :future, users: [user], organisation: organisation, motif: motif, agents: [agent] }

    before do
      visit admin_organisation_user_path(organisation, user)
    end

    it do
      expect(page).to have_content("À venir\n1 RDV")
      click_link "Voir tous les rendez-vous de Tanguy Laverdure"
      expect_page_title("Liste des RDV")
      expect(page).to have_content("Le #{I18n.l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)")
    end
  end
end
