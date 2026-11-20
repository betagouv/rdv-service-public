RSpec.describe SeedAccounts do
  describe ".filter" do
    it "en production sans IS_REVIEW_APP, retourne []" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      expect(described_class.filter(kind: :agents, domain: Domain::RDV_SOLIDARITES)).to eq([])
    end

    it "en review app, ne retourne que les comptes du domaine demandé et ceux sans domaine" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      with_modified_env(IS_REVIEW_APP: "true") do
        rdvsp_agents = described_class.filter(kind: :agents, domain: Domain::RDV_SERVICE_PUBLIC).map(&:email)
        expect(rdvsp_agents).to include("alain.mairie@rdv-mairie-demo.fr", "superviseur.fictif@staging.rdv-service-public.fr", "camille-clavier@demo.rdv-solidarites.fr")
        expect(rdvsp_agents).not_to include("martine@demo.rdv-solidarites.fr")

        rdvs_users = described_class.filter(kind: :users, domain: Domain::RDV_SOLIDARITES).map(&:email)
        expect(rdvs_users).to include("patricia_duroy@demo.rdv-solidarites.fr", "email_1@test.com")
        expect(rdvs_users).not_to include("loulou@exemple.fr")
      end
    end
  end
end
