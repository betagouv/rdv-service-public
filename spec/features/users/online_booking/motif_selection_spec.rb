RSpec.describe "Motif selection" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  before { travel_to(now) }

  context "when two motifs have slightly different names because of understandable human error" do
    let!(:motif) { create(:motif, name: "RDV Intégration direct' emploi", organisation: organisation, service: service) }
    let!(:autre_motif) { create(:motif, name: "RDV integration direct'emploi", organisation: autre_organisation, service: service) }
    let(:encore_autre_motif) { create(:motif, name: "Vaccination", organisation: organisation, service: service) }
    let(:organisation) { create(:organisation) }
    let(:autre_organisation) { create(:organisation, territory: organisation.territory) }

    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }
    let!(:autre_plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [autre_motif], lieu: autre_lieu, organisation: autre_organisation) }
    let!(:encore_autre_plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [encore_autre_motif], lieu: encore_autre_lieu, organisation: autre_organisation) }

    let(:lieu) { create(:lieu, organisation: organisation, name: "Premier lieu") }
    let(:autre_lieu) { create(:lieu, organisation: autre_organisation, name: "Deuxième lieu") }
    let(:encore_autre_lieu) { create(:lieu, organisation: organisation, name: "Troisième lieu") }
    let(:service) { create(:service) }

    it "displays only one motif and then allows to choose between the two different lieux" do
      visit prendre_rdv_path(service_id: service.id, departement: organisation.territory.departement_number)
      expect(page).to have_content(motif.name)
      expect(page).not_to have_content(autre_motif.name)
      expect(page).to have_content(encore_autre_motif.name)

      click_link(motif.name)

      expect(page).to have_content(lieu.name)
      expect(page).to have_content(autre_lieu.name)
      expect(page).not_to have_content(encore_autre_lieu.name)
    end
  end

  context "un seul motif dans le service" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:lieu) { create(:lieu, organisation: organisation, name: "MDS Centre") }
    let!(:motif) { create(:motif, name: "premier contact", organisation: organisation, service: service) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }

    it "le choix de motif est quand même présenté et on peut revenir depuis l’étape suivante" do
      visit prendre_rdv_path(service_id: service.id, departement: organisation.territory.departement_number)
      expect(page).to have_content("Sélectionnez le motif")
      expect(page).to have_content("premier contact")
      click_link("premier contact")
      expect(page).to have_content("Sélectionnez un lieu de RDV")
      expect(page).to have_content("MDS Centre")
      click_link("premier contact") # c’est le lien retour
      expect(page).to have_content("Sélectionnez le motif")
    end
  end
end
