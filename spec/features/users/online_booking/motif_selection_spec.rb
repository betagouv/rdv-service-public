RSpec.describe "Motif selection" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  before { travel_to(now) }

  context "when two motifs have slightly different names because of understandable human error" do
    let!(:motif) { create(:motif, name: "RDV Intégration direct' emploi", organisation: organisation, service: service) }
    let!(:autre_motif) { create(:motif, name: "RDV intégration direct'emploi", organisation: autre_organisation, service: service) }
    let(:organisation) { create(:organisation) }
    let(:autre_organisation) { create(:organisation, territory: organisation.territory) }

    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }
    let!(:autre_plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [autre_motif], lieu: autre_lieu, organisation: autre_organisation) }

    let(:lieu) { create(:lieu, organisation: organisation, name: "Premier lieu") }
    let(:autre_lieu) { create(:lieu, organisation: autre_organisation, name: "Deuxième lieu") }
    let(:service) { create(:service) }

    it "displays only one motif and then allows to choose betwen the two different lieux" do
      visit prendre_rdv_path(service_id: service.id, departement: organisation.territory.departement_number)
      expect(page).to have_content(motif.name)
      expect(page).not_to have_content(motif.name)

      click_link(motif.name)

      expect(page).to have_content(lieu.name)
      expect(page).to have_content(autre_lieu.name)
    end
  end
end
