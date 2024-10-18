require "swagger_helper"

RSpec.describe "Available Creneaux Count for Invitation" do
  with_examples
  let!(:now) { Time.zone.parse("2023-10-23 16:00") }

  before do
    travel_to(now)
  end

  path "/api/rdvinsertion/invitations/creneau_availability" do
    get "Renvoi true si au moins un créneau est disponible pour une invitation" do
      with_authentication

      tags "CreneauxCount"
      produces "application/json"
      operationId "availableCreneauxCount"
      description "Renvoi true si au moins un créneau est disponible pour une invitation"

      parameter name: "invitation_token", in: :query, type: :string, description: "Le token d'invitation", example: "123456789", required: false
      parameter name: "address", in: :query, type: :string, description: "L'adresse de recherche", example: "1 rue de la paix", required: false
      parameter name: "latitude", in: :query, type: :string, description: "La latitude de recherche", example: "45.188529", required: false
      parameter name: "longitude", in: :query, type: :string, description: "La longitude de recherche", example: "5.724524", required: false
      parameter name: "city_code", in: :query, type: :string, description: "Le code INSEE de la commune de recherche", example: "26001", required: false
      parameter name: "departement", in: :query, type: :string, description: "Le numéro ou code de département de recherche", example: "26", required: false
      parameter name: "street_ban_id", in: :query, type: :string, description: "L'ID de la voie de recherche", example: "260010000Rue de la Paix", required: false
      parameter name: "motif_category_short_name", in: :query, type: :string, description: "Le nom court de la catégorie de motif de recherche", example: "rsa_orientation", required: false
      parameter name: "lieu_id", in: :query, type: :string, description: "L'ID du lieu de recherche", example: "1", required: false
      parameter name: "organisation_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "Les IDs des organisations de recherche", example: %w[1 2 3], required: false
      parameter name: "referent_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "Les IDs des référents de recherche", example: %w[1 2 3], required: false

      let!(:user) { create(:user, organisations: [organisation1], rdv_invitation_token: "user_token") }
      let!(:user_with_referent) { create(:user, referent_agents: [agent], organisations: [organisation1], rdv_invitation_token: "user_with_referent_token") }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation1]) }
      let!(:territory33) { create(:territory, departement_number: "33") }
      let!(:territory92) { create(:territory, departement_number: "92") }

      let!(:organisation1) { create(:organisation, territory: territory33) }
      let!(:org_with_secto) { create(:organisation, territory: territory33) }
      let!(:other_org_without_po) { create(:organisation, territory: territory33) }

      let!(:sector) { create(:sector, territory: territory33) }
      let!(:sector_attribution) { create(:sector_attribution, sector: sector, organisation: org_with_secto) }
      let!(:zone_attributes) do
        {
          sector: sector,
          level: "city",
          city_name: "Bordeaux",
          city_code: "33000",
        }
      end

      let!(:rsa_orientation) { create(:motif_category, name: "RSA orientation sur site", short_name: "rsa_orientation") }
      let!(:rsa_orientation_on_phone_platform) { create(:motif_category, name: "RSA orientation sur plateforme téléphonique", short_name: "rsa_orientation_on_phone_platform") }

      let!(:motif) do
        create(
          :motif,
          min_public_booking_delay: 3.days,
          max_public_booking_delay: 1.month,
          bookable_by: "agents_and_prescripteurs_and_invited_users",
          name: "RSA orientation",
          motif_category: rsa_orientation,
          organisation: organisation1
        )
      end
      let!(:motif2) do
        create(
          :motif,
          min_public_booking_delay: 3.days,
          max_public_booking_delay: 1.month,
          bookable_by: "agents_and_prescripteurs_and_invited_users",
          name: "RSA orientation phone",
          motif_category: rsa_orientation_on_phone_platform,
          organisation: organisation1
        )
      end
      let!(:motif_follow_up) do
        create(
          :motif,
          follow_up: true,
          min_public_booking_delay: 3.days,
          max_public_booking_delay: 1.month,
          bookable_by: "agents_and_prescripteurs_and_invited_users",
          name: "RSA orientation",
          motif_category: rsa_orientation,
          organisation: organisation1
        )
      end
      let!(:motif_with_secto) do
        create(
          :motif,
          min_public_booking_delay: 3.days,
          max_public_booking_delay: 1.month,
          bookable_by: "agents_and_prescripteurs_and_invited_users",
          name: "Motif numéro 4",
          sectorisation_level: Motif::SECTORISATION_LEVEL_ORGANISATION,
          organisation: org_with_secto
        )
      end

      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation1) }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], lieu: lieu2, organisation: organisation1) }
      let!(:plage_ouverture_follow_up) { create(:plage_ouverture, agent: agent, motifs: [motif_follow_up], lieu: lieu2, organisation: organisation1) }
      let!(:plage_ouverture_with_secto) { create(:plage_ouverture, motifs: [motif_with_secto], lieu: lieu, organisation: org_with_secto) }

      let!(:lieu) { create(:lieu, name: "Bordeaux Centre", address: "Place de la bourse, Bordeaux, 33000", organisation: organisation1) }
      let!(:lieu2) { create(:lieu, name: "Bruges", address: "3 Rue Gabriel Fauré, Bruges, 33520", organisation: organisation1) }
      let!(:lieu3) { create(:lieu, name: "Loin de Bordeaux", address: "7 Av. du Commandant l'Herminier, Arès, 33740", organisation: other_org_without_po) }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Retourne false quand il n'y a pas de créneau disponible" do
        run_test!

        it "Quand il n'y a pas de params" do
          expect(parsed_response_body["creneau_availability"]).to be_falsey
        end

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "invitations",
            action_name: "creneau_availability",
            agent_id: agent.id,
            received_at: now
          )
          expect(ApiCall.first.raw_http["method"]).to eq("GET")
          expect(ApiCall.first.raw_http["headers"]).to include("HTTP_ACCEPT")
          expect(ApiCall.first.raw_http["headers"]).not_to include("rack.session.options")
          expect(ApiCall.first.raw_http["headers"]["HTTP_ACCEPT"]).to eq("application/json")
        end

        context "Si le lieu n'existe pas" do
          let!(:lieu_id) { "666" }

          it do
            expect(parsed_response_body["creneau_availability"]).to be_falsey
            expect(parsed_response_body["error"]).to eq("Couldn't find Lieu with 'id'=666")
          end
        end

        context "Avec un lieu d'une autre organisation" do
          let!(:lieu_id) { lieu3.id }
          let!(:"organisation_ids[]") { [organisation1.id] }

          it { expect(parsed_response_body["creneau_availability"]).to be_falsey }
        end

        context "Avec un département sans plage d'ouverture" do
          let!(:departement) { "92" }

          it { expect(parsed_response_body["creneau_availability"]).to be_falsey }
        end

        context "Avec une organisation sans plage d'ouverture" do
          let!(:"organisation_ids[]") { [other_org_without_po.id] }

          it { expect(parsed_response_body["creneau_availability"]).to be_falsey }
        end

        context "Avec un motif_category_shortname qui n'existe pas" do
          let!(:motif_category_short_name) { "autre_categorie" }
          let!(:"organisation_ids[]") { [organisation1.id] }

          it { expect(parsed_response_body["creneau_availability"]).to be_falsey }
        end

        context "Quand le user est spécifié" do
          let!(:invitation_token) { "user_with_referent_token" }

          context "Avec des ids de référents invalides" do
            let!(:"referent_ids[]") { %w[5 6] }
            let!(:"organisation_ids[]") { [organisation1.id] }

            it { expect(parsed_response_body["creneau_availability"]).to be_falsey }
          end
        end
      end

      response 200, "Retourne true quand il y a des créneaux disponibles" do
        run_test!

        context "Avec le params lieu_id" do
          let!(:lieu_id) { lieu.id }
          let!(:"organisation_ids[]") { [organisation1.id] }

          it { expect(parsed_response_body["creneau_availability"]).to be_truthy }

          it "logs the API call" do
            expect(ApiCall.first.attributes.symbolize_keys).to include(
              controller_name: "invitations",
              action_name: "creneau_availability",
              agent_id: agent.id,
              received_at: now
            )
            expect(ApiCall.first.raw_http["method"]).to eq("GET")
            expect(ApiCall.first.raw_http["headers"]).to include("HTTP_ACCEPT")
            expect(ApiCall.first.raw_http["headers"]["HTTP_ACCEPT"]).to eq("application/json")
          end
        end

        context "Avec le params organisation_ids[]" do
          let!(:"organisation_ids[]") { [organisation1.id, other_org_without_po.id] }

          it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
        end

        context "Avec un numéro de département" do
          let!(:departement) { "33" }

          it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
        end

        context "Avec un motif_category_shortname" do
          let!(:motif_category_short_name) { "rsa_orientation" }
          let!(:"organisation_ids[]") { [organisation1.id] }

          it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
        end

        context "Quand le user est spécifié" do
          let!(:invitation_token) { "user_token" }

          context "avec un user et son organisation" do
            let!(:"organisation_ids[]") { [organisation1.id] }

            it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
          end

          context "avec un referent_ids" do
            let!(:"referent_ids[]") { [agent.id] }
            let!(:invitation_token) { "user_with_referent_token" }
            let!(:"organisation_ids[]") { [organisation1.id] }

            it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
          end

          context "Avec un motif_category_shortname" do
            let!(:motif_category_short_name) { "rsa_orientation" }
            let!(:"organisation_ids[]") { [organisation1.id] }

            it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
          end

          context "avec une adresse complète et la sectorisation" do
            let!(:"organisation_ids[]") { [org_with_secto.id] }
            let!(:address) { "Place de la Bourse, Bordeaux, 33000" }
            let!(:city_code) { "33063" }
            let!(:street_ban_id) { "33063_1155" }

            it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
          end

          context "avec une adresse complète et sans sectorisation" do
            let!(:departement) { "33" }
            let!(:address) { "Place de la Bourse, Bordeaux, 33000" }
            let!(:city_code) { "33063" }
            let!(:street_ban_id) { "33063_1155" }

            it { expect(parsed_response_body["creneau_availability"]).to be_truthy }
          end
        end
      end
    end
  end
end
