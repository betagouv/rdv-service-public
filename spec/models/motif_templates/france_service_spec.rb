RSpec.describe MotifTemplates::FranceService do
  describe ".upsert_services!" do
    it "upserts services as well" do
      service_names = ["Allocations familiales (CAF)", "Assurance maladie (CPAM)", "Assurance retraite (CARSAT)", "Chèque énergie",
                       "Finances publiques (DDFiP)", "France Rénov'", "France Titres", "France Travail", "Mutualité sociale agricole", "Urssaf",]
      expect { described_class.upsert_services! }.to change { Service.pluck(:name).uniq.sort }.from([]).to(service_names)
    end
  end

  describe ".upsert_motifs!" do
    let!(:organisation) { create(:organisation) }

    it "creates all motifs from templates" do
      described_class.upsert_services!
      expect { described_class.upsert_motifs!(organisation) }.to change(Motif, :count).by(29)
      expect(Motif.distinct(:default_duration_in_min).pluck(:default_duration_in_min)).to contain_exactly(30, 45, 60)
    end

    it "crashes if services are not created first" do
      expect { described_class.upsert_motifs!(organisation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when some motifs already exist" do
      it "does not create them (upsert)" do
        described_class.upsert_services!
        service = Service.find_by!(name: "Allocations familiales (CAF)")
        create(:motif, organisation:, service:, name: "Déclarer un changement de situation", location_type: :public_office)
        create(:motif, organisation:, service:, name: "Réaliser une déclaration trimestrielle ou annuelle des ressources", location_type: :public_office)
        expect { described_class.upsert_motifs!(organisation) }.to change(Motif, :count).by(27)

        # si on relance l'upsert, on constate qu'il est idempotent
        expect { described_class.upsert_motifs!(organisation) }.to change(Motif, :count).by(0)
      end
    end
  end
end
