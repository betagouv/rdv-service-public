RSpec.describe "Sectorisation display for motifs" do
  let(:territory) { create(:territory, departement_number: "26") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before { login_as(agent, scope: :agent) }

  context "when the organisation doesn't use sectorisation" do
    let!(:motif) { create(:motif, :sectorisation_level_departement, organisation: organisation, bookable_by: :everyone) }

    it "doesn't display the sectorisation level in the motif index" do
      visit admin_organisation_motifs_path(organisation)
      expect(page).not_to have_content("Sectorisation")
      expect(page).not_to have_content("Tout le 26")
    end
  end

  context "when the organisation uses sectorisation" do
    let!(:motif_with_sectorisation) { create(:motif, :sectorisation_level_organisation, organisation: organisation, bookable_by: :everyone) }
    let!(:motif_without_sectorisation) { create(:motif, :sectorisation_level_departement, organisation: organisation, bookable_by: :everyone) }

    it "doesn't display the sectorisation level in the motif index" do
      visit admin_organisation_motifs_path(organisation)
      expect(page).to have_content("aucun secteur")
      expect(page).to have_content("Tout le 26")
    end
  end
end
