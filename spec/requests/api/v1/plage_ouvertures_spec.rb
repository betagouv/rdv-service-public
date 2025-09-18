RSpec.describe "Plage ouvertures API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application, default_service: create(:service)) }

  let!(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, organisation:) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:motif_external_reference) do
    create(:external_reference, item: motif, external_id: 123, oauth_application: application, territory_id: nil)
  end
  let!(:lieu_external_reference) { create(:external_reference, item: lieu, external_id: 456, oauth_application: application, territory_id: nil) }

  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  describe "#create" do
    let(:params) do
      {
        title: "Dispo",
        recurrence: nil,
        first_day: Time.zone.today.strftime("%Y-%m-%d"),
        start_time: "08:00",
        end_time: "12:00",
        lieu_external_id: lieu_external_reference.external_id,
        motif_external_ids: [motif_external_reference.external_id],
        organisation_id: organisation.id,

        external_reference: { external_id: "789" },
      }
    end

    it "creates the plage_ouverture" do
      expect { post "/api/v1/plage_ouvertures", headers:, params:, as: :json }.to change(PlageOuverture, :count)

      expect(response.status).to eq 200
      expect(parsed_response_body["title"]).to eq "Dispo"

      expect(PlageOuverture.last).to have_attributes(
        title: "Dispo",
        lieu_id: lieu.id,
        motif_ids: [motif.id]
      )
    end

    context "quand on ne trouve pas le lieu par l'external id" do
      before do
        params[:lieu_external_id] = "123456"
      end

      it "returns a 404 status" do
        expect { post "/api/v1/plage_ouvertures", headers:, params:, as: :json }.not_to change(PlageOuverture, :count)

        expect(response.status).to eq 404

        expect(parsed_response_body["error_messages"].first).to eq "Aucun lieu trouvé pour le lieux_external_id 123456"
      end
    end

    context "quand on ne trouve pas le motif par external id" do
      before do
        params[:motif_external_ids] = %w[123456 345678]
      end

      it "returns a 404 status" do
        expect { post "/api/v1/plage_ouvertures", headers:, params:, as: :json }.not_to change(PlageOuverture, :count)

        expect(response.status).to eq 404

        expect(parsed_response_body["error_messages"].first).to eq "Certains motifs n'ont pas été trouvés pour les motif_external_ids 123456, 345678"
      end
    end
  end
end
