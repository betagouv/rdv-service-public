RSpec.describe Compte do
  context "when the agent already has an account because they logged in with ProConnect" do
    let!(:agent) { create(:agent) }
    let(:super_admin) { create(:super_admin) }
    let(:service) { create(:service) }

    it "creates the organisation and adds the agent" do
      described_class.new(
        {
          territory: {
            name: "Montreuil", departement_number: 93,
          },
          organisation: { name: "Mairie de Montreuil", ants_connectable: false },
          lieu: { address: "1 rue de la république", latitude: 48.859, longitude: 2.347 },
          agent: { first_name: "Francis", last_name: "Factice", email: agent.email, service_ids: [service.id] },
        },
        current_domain: Domain::RDV_SERVICE_PUBLIC
      ).save!

      expect(agent.reload.roles.last).to have_attributes(access_level: "admin")
      expect(agent.organisations.last.name).to eq "Mairie de Montreuil"
    end

    context "when another super admin has already responded to the territory creation request" do
      let(:territory_creation_request) { create(:territory_creation_request, response: :refused) }

      it "raises an error" do
        compte = described_class.new(
          {
            territory: {
              name: "Montreuil", departement_number: 93,
            },
            organisation: { name: "Mairie de Montreuil", ants_connectable: false },
            lieu: { address: "1 rue de la république", latitude: 48.859, longitude: 2.347 },
            agent: { first_name: "Francis", last_name: "Factice", email: agent.email, service_ids: [service.id] },
          },
          current_domain: Domain::RDV_SERVICE_PUBLIC,
          territory_creation_request:
        )

        expect { compte.save! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Territory.last).to be_nil
        expect(territory_creation_request.reload.response).to eq "refused"
      end
    end

    context "ANTS connectable est activé" do
      let!(:cni_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
      let!(:passport_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
      let!(:cni_passport_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME) }

      it "attache les catégories de motifs ANTS au territoire créé" do
        described_class.new(
          {
            territory: {
              name: "Montreuil", departement_number: 93,
            },
            organisation: { name: "Mairie de Montreuil", ants_connectable: true },
            lieu: { address: "1 rue de la république", latitude: 48.859, longitude: 2.347 },
            agent: { first_name: "Francis", last_name: "Factice", email: agent.email, service_ids: [service.id] },
          },
          current_domain: Domain::RDV_SERVICE_PUBLIC
        ).save!

        expect(agent.reload.roles.last).to have_attributes(access_level: "admin")
        expect(agent.organisations.last.territory.name).to eq("Montreuil")
        expect(agent.organisations.last.territory.motif_categories).to contain_exactly(cni_category, passport_category, cni_passport_category)
      end
    end
  end

  describe ".upsert_france_service_motifs!" do
    it "creates all motifs from templates" do
      organisation = create(:organisation)
      expect { described_class.upsert_france_service_motifs!(organisation) }.to change(Motif, :count).by(29)
      expect(Motif.distinct(:default_duration_in_min).pluck(:default_duration_in_min)).to contain_exactly(30, 45, 60)
    end

    context "when some motifs already exist" do
      it "does not create them (upsert)" do
        organisation = create(:organisation)
        service = create(:service, name: "Allocations familiales (CAF)", short_name: "Allocations familiales (CAF)")
        create(:motif, organisation:, service:, name: "Déclarer un changement de situation", location_type: :public_office)
        create(:motif, organisation:, service:, name: "Réaliser une déclaration trimestrielle ou annuelle des ressources", location_type: :public_office)
        expect { described_class.upsert_france_service_motifs!(organisation) }.to change(Motif, :count).by(27)

        # si on relance l'upsert, on constate qu'il est idempotent
        expect { described_class.upsert_france_service_motifs!(organisation) }.to change(Motif, :count).by(0)
      end
    end
  end
end
