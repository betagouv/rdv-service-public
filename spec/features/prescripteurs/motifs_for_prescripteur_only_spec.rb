# frozen_string_literal: true

RSpec.describe "motifs for prescripteurs only", js: true do
  let(:organisation) { create(:organisation, territory: territory, name: "MDS du quartier") }
  let(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, name: "Accompagnement individuel", organisation: organisation, bookable_by: :agents) }

  before do
    login_as(agent, scope: :agent)
  end

  context "when the territory has the prescripteur beta feature enabled" do
    let(:territory) { create(:territory, departement_number: "83") }

    specify "setting a motif as prescripteurs only from the agents form" do
      visit edit_admin_organisation_motif_path(organisation, motif)
      expect(page).not_to have_content("Délai minimum de réservation")
      expect(page).not_to have_content("Ouvert aux agents, aux prescripteurs et aux usagers avec une invitation")

      choose("Ouvert aux agents et aux prescripteurs")
      expect(page).to have_content("Délai minimum de réservation")

      click_button("Enregistrer")

      expect(page).to have_content("Ouvert aux agents et aux prescripteurs")
    end
  end

  context "when the territory doesn't have that feature enabled" do
    let(:territory) { create(:territory, departement_number: "26") }

    it "doesn't show the possibility to have prescripteurs and toggles the online booking options properly" do
      visit edit_admin_organisation_motif_path(organisation, motif)
      expect(page).not_to have_content("Ouvert aux agents et aux prescripteurs")

      expect(page).not_to have_content("Délai minimum de réservation")

      choose("Ouvert aux agents et aux usagers")

      expect(page).to have_content("Délai minimum de réservation")

      choose("Uniquement les agents de MDS du quartier")

      expect(page).not_to have_content("Délai minimum de réservation")
    end
  end

  context "when organisation's verticale is rdv_insertion" do
    let!(:organisation) { create(:organisation, territory: territory, name: "PE", verticale: "rdv_insertion") }

    context "when the territory has the prescripteur beta feature enabled" do
      let(:territory) { create(:territory, departement_number: "83") }

      specify "setting a motif as prescripteurs and invited users from the agents form" do
        visit edit_admin_organisation_motif_path(organisation, motif)

        choose("Ouvert aux agents, aux prescripteurs et aux usagers avec une invitation")
        expect(page).to have_content("Délai minimum de réservation")

        click_button("Enregistrer")

        expect(page).to have_content("Ouvert aux agents, aux prescripteurs et aux usagers avec une invitation")
      end
    end

    context "when the territory doesn't have that feature enabled" do
      let(:territory) { create(:territory, departement_number: "26") }

      it "doesn't show the possibility to have prescripteurs in bookable_by options" do
        visit edit_admin_organisation_motif_path(organisation, motif)

        choose("Ouvert aux agents et aux usagers avec une invitation")
        expect(page).to have_content("Délai minimum de réservation")

        click_button("Enregistrer")

        expect(page).to have_content("Ouvert aux agents et aux usagers avec une invitation")
      end
    end
  end
end
