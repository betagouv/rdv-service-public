RSpec.describe "motifs for invitation only" do
  let(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, name: "Accompagnement individuel", organisation: organisation, bookable_by: :agents) }

  before do
    login_as(agent, scope: :agent)
  end

  context "when organisation's verticale is not rdv_insertion" do
    let(:organisation) { create(:organisation, territory: territory, name: "MDS du quartier") }
    let(:territory) { create(:territory, departement_number: "83") }

    specify "setting a motif as prescripteurs only from the agents form", js: true do
      visit edit_admin_organisation_motif_path(organisation, motif)
      click_on "Réservation en ligne"

      expect(page).not_to have_content("Délai minimum de réservation")
      expect(page).not_to have_content("Ouvert aux agents, aux prescripteurs et aux usagers avec une invitation")

      choose("Seuls vous et les agents de votre structure peuvent ajouter des rendez-vous à votre agenda.")
      expect(page).to have_content("Délai minimum avant le RDV")

      click_button("Enregistrer")

      expect(page).to have_content("Seuls vous et les agents de votre structure peuvent ajouter des rendez-vous à votre agenda")
    end
  end

  context "when organisation's verticale is rdv_insertion" do
    let!(:organisation) { create(:organisation, territory: territory, name: "PE", verticale: "rdv_insertion") }
    let(:territory) { create(:territory, departement_number: "83") }

    specify "setting a motif as prescripteurs and invited users from the agents form", js: true do
      visit edit_admin_organisation_motif_path(organisation, motif)
      click_on "Réservation en ligne"

      choose("Créneaux ouverts à la réservation en ligne via une invitation")
      expect(page).to have_content("Délai minimum avant le RDV")

      click_button("Enregistrer")

      expect(page).to have_content("Les agents, prescripteurs, et usagers peuvent ajouter des rendez-vous dans votre agenda.")
    end
  end
end
