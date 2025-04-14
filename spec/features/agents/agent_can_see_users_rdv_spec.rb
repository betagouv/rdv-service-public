# TODO: faire version pour un motif sans service
RSpec.describe "can see users' RDV" do
  context "with no RDV" do
    let!(:organisation) { create(:organisation) }
    let!(:service) { create(:service) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
    let!(:user) { create(:user, first_name: "Tanguy", last_name: "Laverdure", organisations: [organisation]) }
    let!(:motif) { create(:motif, organisation: organisation, service: service) }

    it do
      login_as(agent, scope: :agent)
      visit admin_organisation_user_path(organisation, user)
      expect(page).to have_content("À venir\n0 RDV")
      expect(page).to have_content("aucun RDV")
    end
  end

  context "with one RDV" do
    let!(:organisation) { create(:organisation) }
    let!(:service) { create(:service) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
    let!(:user) { create(:user, first_name: "Tanguy", last_name: "Laverdure", organisations: [organisation]) }
    let!(:motif) { create(:motif, organisation: organisation, service: service) }

    let!(:rdv) { create :rdv, :future, users: [user], organisation: organisation, motif: motif, agents: [agent] }

    before do
      create(:rdv, :past, status: :seen, users: [user], organisation: organisation, motif: motif, agents: [agent])
      create(:rdv, :past, status: :excused, users: [user], organisation: organisation, motif: motif, agents: [agent])
      create(:rdv, :past, status: :revoked, users: [user], organisation: organisation, motif: motif, agents: [agent])
      create(:rdv, :past, status: :noshow, users: [user], organisation: organisation, motif: motif, agents: [agent])
    end

    it do
      login_as(agent, scope: :agent)
      visit admin_organisation_user_path(organisation, user)

      expect(page).to have_content("Excusé\n1 RDV")
      expect(page).to have_content("Vu\n1 RDV")
      expect(page).to have_content("Annulé par un agent\n1 ")
      expect(page).to have_content("Non excusé\n1 ")

      expect(page).to have_content("À venir\n1 RDV")
      click_link "Voir tous les rendez-vous de Tanguy LAVERDURE"
      expect_page_title("Liste des RDV")
      expect(page).to have_content("Le #{I18n.l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)")
    end
  end

  describe "displaying annotations" do
    let!(:territory) { create(:territory, enable_notes_field: true) }
    let!(:organisation) { create(:organisation, territory:) }
    let!(:responsible) { create(:user, organisations: [organisation]) }
    let!(:relative) { create(:user, organisations: [organisation], responsible:) }

    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    it "works" do
      login_as(agent, scope: :agent)
      visit admin_organisation_user_path(organisation, relative)
      # On visite pour vérifier que la page ne crash pas en l'absence d'annotation, voir #5133.
      expect(page).to have_content("Informations de votre proche")

      responsible.annotate!("Ce responsable est très responsable", territory:)
      relative.annotate!("Ce proche est très proche", territory:)

      # Sur la page du proche, on affiche les remarques du responsable ET du proche
      visit admin_organisation_user_path(organisation, relative)
      expect(page).to have_content("Ce responsable est très responsable")
      expect(page).to have_content("Ce proche est très proche")

      # Sur la page du responsable, on affiche uniquement la remarque du responsable
      visit admin_organisation_user_path(organisation, responsible)
      expect(page).to have_content("Ce responsable est très responsable")
      expect(page).not_to have_content("Ce proche est très proche")
    end
  end
end
