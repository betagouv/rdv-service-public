RSpec.describe MotifTemplates::FranceService do
  subject { described_class.new(organisation) }

  let!(:organisation) { create(:organisation) }

  describe "services creation" do
    it "creates services for the motifs if they don't exist" do
      service_names = ["Allocations familiales (CAF)", "Assurance maladie (CPAM)", "Assurance retraite (CARSAT)", "Chèque énergie",
                       "Finances publiques (DDFiP)", "France Rénov'", "France Titres", "France Travail", "Mutualité sociale agricole", "Urssaf",]
      expect { subject.upsert }.to change { Service.pluck(:name).uniq.sort }.from([]).to(service_names)
    end

    it "adds the services to the organisation's territory" do
      expect { subject.upsert }.to change { organisation.territory.services.count }.from(0).to(10)
    end
  end

  describe "motifs creation" do
    it "creates all motifs from templates" do
      expect { subject.upsert }.to change(Motif, :count).by(29)
      expect(Motif.distinct(:default_duration_in_min).pluck(:default_duration_in_min)).to contain_exactly(30, 45, 60)
    end

    context "when some motifs already exist" do
      before do
        service = create(:service, name: "Allocations familiales (CAF)")
        create(:motif, organisation:, service:, name: "Déclarer un changement de situation", location_type: :public_office)
        create(:motif, organisation:, service:, name: "Réaliser une déclaration trimestrielle ou annuelle des ressources", location_type: :public_office)
      end

      it "does not create them (upsert)" do
        expect { subject.upsert }.to change(Motif, :count).by(27)

        # si on relance l'upsert, on constate qu'il est idempotent
        expect { subject.upsert }.not_to change(Motif, :count)
      end
    end
  end
end
