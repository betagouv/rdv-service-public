RSpec.describe "prescripteurs pages", driver: :playwright_bypass_csp, js: true do
  let(:territory) { create(:territory, departement_number: "75") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:motif) { create(:motif, organisation: organisation, name: "Consultation prénatale") }
  let(:autre_motif) { create(:motif, organisation: organisation, service: motif.service) }

  let!(:po_pour_motif) { create(:plage_ouverture, motifs: [motif], lieu: lieu) }

  it "saisie info prescripteurs" do
    # TODO: A implémenter
    expect(true).to be_truthy
  end
end
