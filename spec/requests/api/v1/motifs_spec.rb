RSpec.describe "Motifs API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application, default_service: create(:service)) }

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  describe "#create" do
    context "without an external reference" do
      let(:params) do
        {
          name: "Suivi de dossier",
          organisation_id: organisation.id,
          color: "#000000",
          default_duration_in_min: 30,
          min_public_booking_delay: 1800,
          max_public_booking_delay: 7889238,
          collectif: false,
          bookable_by: "everyone",
        }
      end

      it "creates the motif" do
        expect { post "/api/v1/motifs", headers:, params:, as: :json }.to change(Motif, :count)

        expect(response.status).to eq 200
        expect(parsed_response_body["name"]).to eq "Suivi de dossier"
      end
    end

    context "when calling the endpoint twice with the same external reference" do
      let(:params) do
        {
          name: "Suivi de dossier",
          organisation_id: organisation.id,
          color: "#000000",
          default_duration_in_min: 30,
          min_public_booking_delay: 1800,
          max_public_booking_delay: 7889238,
          collectif: false,
          bookable_by: "everyone",
          external_reference: { external_id: "123ABC" },
        }
      end

      it "creates only one motif and returns an error message on the second call" do
        expect { post "/api/v1/motifs", headers:, params:, as: :json }.to change(Motif, :count)

        expect { post "/api/v1/motifs", headers:, params:, as: :json }.not_to change(Motif, :count)

        expect(response.status).to eq 422
        expect(parsed_response_body).to eq ApiSpecHelper.external_id_error_response
      end
    end

    context "when the motif is not valid for another reason" do
      let(:params) do
        {
          name: "Suivi de dossier",
          organisation_id: organisation.id,
          color: "#000000",
          default_duration_in_min: 30,
          min_public_booking_delay: 1800,
          max_public_booking_delay: 7889238,
          collectif: false,
          bookable_by: "everyone",
          external_reference: { external_id: "123ABC" },
        }
      end

      let!(:existing_motif) do
        create(:motif, organisation_id: organisation.id, name: "Suivi de dossier")
      end

      it "doesn't create the motif and returns an error message" do
        expect { post "/api/v1/motifs", headers:, params:, as: :json }.not_to change(Motif, :count)

        expect(response.status).to eq 422
        expect(parsed_response_body).to eq ApiSpecHelper.invalid_motif_response(organisation.name)
      end
    end
  end
end
