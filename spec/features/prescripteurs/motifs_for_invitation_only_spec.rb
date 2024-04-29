RSpec.describe "motifs for invitation only" do
  let(:territory) { create(:territory, departement_number: "83", services: [create(:service)]) }
  let(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, name: "Accompagnement individuel", organisation: organisation, bookable_by: :agents) }

  before do
    login_as(agent, scope: :agent)
  end

  context "when organisation's verticale is not rdv_insertion" do
    let(:organisation) { create(:organisation, territory: territory, name: "MDS du quartier") }

    specify "setting a motif as prescripteurs only from the agents form", js: true do
      visit edit_admin_organisation_motif_path(organisation, motif)
      click_on "Réservation en ligne"

      expect(page).not_to have_content("Ouvert aux agents, aux prescripteurs et aux usagers avec une invitation")

      expect(page).to have_field("Délai minimum avant le RDV", disabled: true)
      choose("Créneaux accessibles aux agents de l’organisation et aux prescripteurs")
      expect(page).to have_field("Délai minimum avant le RDV", disabled: false)

      expect { click_button("Enregistrer") }.to change { motif.reload.bookable_by }.to("agents_and_prescripteurs")
    end
  end

  context "when organisation's verticale is rdv_insertion" do
    let!(:organisation) { create(:organisation, territory: territory, name: "PE", verticale: "rdv_insertion") }

    specify "setting a motif as prescripteurs and invited users from the agents form", js: true do
      visit edit_admin_organisation_motif_path(organisation, motif)
      click_on "Réservation en ligne"

      choose("Créneaux accessibles aux agents de l’organisation, aux prescripteurs et aux usagers via une invitation")
      expect(page).to have_content("Délai minimum avant le RDV")

      expect { click_button("Enregistrer") }.to change { motif.reload.bookable_by }.to("agents_and_prescripteurs_and_invited_users")
    end
  end
end
