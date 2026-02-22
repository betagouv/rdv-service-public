require "swagger_helper"

RSpec.describe "RDV authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/rdvs" do
    get "Lister les rendez-vous" do
      with_authentication

      tags "RDV"
      produces "application/json"
      operationId "getRdvs"

      # L'usage du paramètre `include` est expliqué dans la description plutôt qu'en tant qu'un paramètre séparé, parce que la
      # meta-programmation utilisée par le matcher rspec et rswag-spec entrent en conflit.
      # En décommentant la ligne suivant on a cette erreur : ArgumentError: include() is not supported, please supply an argument
      # parameter name: :include, in: :query, description: "Indique quelles associations charger dans la réponse", example: "include[]=&status[]=revoked", required: false

      description <<~DESCRIPTION.squish
        Renvoie les RDVs visibles pour l'agent authentifié, en appliquant les filtres facultatifs passés en paramètre.
        <br />
        Par défaut, toutes les associations disponibles sont renvoyées (participants, agents, motif, etc...), ce qui peut
        considérablement ralentir le temps de réponse.
        Vous pouvez passer le paramètre `include` pour choisir quelles associations inclure dans la réponse.
        Il prend un tableau de chaines de caractères, et les valeurs possibles sont :
        <ul>
          <li>organisation</li>
          <li>lieu</li>
          <li>motifs</li>
          <li>agents</li>
          <li>users</li>
          <li>participations</li>
        </ul>

        Par exemple, vous pouvez passer `include[]=agents&include[]=users` ou `include=agents,users` en query params.
      DESCRIPTION

      parameter name: :organisation_id, in: :query, type: :string, description: "Identifiant de l'organisation", example: "20", required: false

      parameter name: :user_id, in: :query, type: :integer,
                description: "Filtre pour obtenir uniquement les rendez-vous de l'usager qui a cet id",
                example: 123, required: false
      parameter name: :agent_id, in: :query, type: :integer,
                description: "Filtre pour obtenir uniquement les rendez-vous de l'agent qui a cet id",
                example: 456, required: false
      parameter name: :status, in: :query,
                description: <<~DOC,
                  Filtre les rendez-vous par statut.
                  Vous pouvez passer soit une seule chaine de caractères, soit un tableau de chaines de caractères.
                  Les différentes valeurs possibles sont #{Rdv.statuses.keys}.
                  Si vous passez un tableau, vous pouvez utiliser le format `status[]=excused&status[]=revoked` ou `status=excused,revoked`.
                DOC
                example: "seen ou status[]=excused&status[]=revoked ou status=excused,revoked", required: false

      parameter name: :id, in: :query,
                description: <<~DOC,
                  Filtre pour obtenir uniquement les rendez-vous dont l'id est dans cette liste.
                  Vous pouvez passer soit un tableau d'entier pour obtenir plusieurs rdvs, soit un seul entier pour obtenir un seul rdv.
                  Si vous passez un tableau d'entier, le format attendu est
                  Si vous passez un tableau, vous pouvez utiliser le format id[]=1234&id[]=5678 ou id=1234,5678.
                DOC
                example: "789 ou id[]=1234&id[]=5678 id=1234,5678", required: false

      parameter name: :starts_after, in: :query, type: :string,
                description: "Filtre les rendez-vous avec un starts_at aprés cette date. Accepte des formats date ou time (iso8601).",
                example: "2020-01-01", required: false
      parameter name: :starts_before, in: :query, type: :string,
                description: "Filtre les rendez-vous avec un starts_at avant cette date. Accepte des formats date ou time (iso8601).",
                example: "2020-01-01", required: false

      let(:access_basic_agent) { api_auth_headers_for_agent(basic_agent) }
      let(:"access-token") { access_basic_agent["access-token"].to_s }
      let(:uid) { access_basic_agent["uid"].to_s }
      let(:client) { access_basic_agent["client"].to_s }

      let!(:rdv) { create(:rdv, organisation: organisation, motif: motif, starts_at: "2022-01-01 09:00:00 +0200") }

      let!(:organisation) { organisations(:default_org) }
      let(:service) { create(:service) }
      let(:motif) { create(:motif, organisation: organisation, service: service) }
      let!(:basic_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let(:organisation_id) { organisation.id }

      response 200, "Appel API réussi" do
        schema "$ref" => "#/components/schemas/rdvs"

        run_test!
      end
    end
  end

  path "/api/v1/organisations/{organisation_id}/rdvs" do
    get "Lister les rendez-vous d'une organisation" do
      with_authentication

      tags "RDV"
      produces "application/json"
      operationId "getRdvs"
      description "Renvoie les RDVs du service dont l'agent fait partie dans cette organisation. Si l'agent est administrateurice ou secrétaire, renvoie tous les RDVs de l'organisation en question."

      parameter name: :organisation_id, in: :path, type: :string, description: "Identifiant de l'organisation", example: "20"

      parameter name: :user_id, in: :query, type: :integer,
                description: "Filtre pour obtenir uniquement les rendez-vous de l'usager qui a cet id",
                example: 123, required: false
      parameter name: :agent_id, in: :query, type: :integer,
                description: "Filtre pour obtenir uniquement les rendez-vous de l'agent qui a cet id",
                example: 456, required: false

      parameter name: :starts_after, in: :query, type: :string,
                description: "Filtre les rendez-vous avec un starts_at aprés cette date. Accepte des formats date ou time (iso8601).",
                example: "2020-01-01", required: false
      parameter name: :starts_before, in: :query, type: :string,
                description: "Filtre les rendez-vous avec un starts_at avant cette date. Accepte des formats date ou time (iso8601).",
                example: "2020-01-01", required: false

      let(:access_basic_agent) { api_auth_headers_for_agent(basic_agent) }
      let(:"access-token") { access_basic_agent["access-token"].to_s }
      let(:uid) { access_basic_agent["uid"].to_s }
      let(:client) { access_basic_agent["client"].to_s }

      let!(:organisationA) { create(:organisation) }
      let!(:organisationB) { create(:organisation) }

      let!(:service) { create(:service) }
      let!(:service2) { create(:service) }

      let!(:motifA1) { create(:motif, service: service, organisation: organisationA) }
      let!(:motifA2) { create(:motif, service: service2, organisation: organisationA) }
      let!(:motifB1) { create(:motif, service: service, organisation: organisationB) }
      let!(:motifB2) { create(:motif, service: service2, organisation: organisationB) }
      let!(:motif_sans_service) { create(:motif, service: nil, organisation: organisationA) }

      let!(:rdv) { create(:rdv, organisation: organisationA, motif: motifA1, starts_at: "2022-01-01 09:00:00 +0200") }
      let!(:rdv2) { create(:rdv, organisation: organisationB, motif: motifB1, starts_at: "2023-01-01 09:00:00 +0200") }
      let!(:rdv3) { create(:rdv, organisation: organisationA, motif: motifA2, starts_at: "2024-01-01 09:00:00 +0200") }
      let!(:rdv_sans_service) { create(:rdv, organisation: organisationA, motif: motif_sans_service, starts_at: "2024-01-01 09:00:00 +0200") }

      let!(:basic_agent) { create(:agent, basic_role_in_organisations: [organisationA], service: service) }
      let(:organisation_id) { organisationA.id }

      response 200, "Appel API réussi" do
        schema "$ref" => "#/components/schemas/rdvs"

        run_test!

        it "returns policy scoped RDVs" do
          expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv.id, rdv_sans_service.id)
          expect(response.parsed_body["rdvs"].pluck("created_by").uniq).to contain_exactly("agent")
        end
      end

      response 200, "returns empty results when organisation is not found", document: false do
        let(:organisation_id) { "false" }

        run_test!

        it { expect(response.parsed_body["rdvs"]).to eq([]) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "rdvs",
            action_name: "index",
            agent_id: basic_agent.id
          )
        end
      end

      context "with starts_after and starts_before params" do
        let!(:rdv2020) { create(:rdv, organisation: organisationA, motif: motifA1, starts_at: "2020-01-01 09:00:00 +0200") }
        let!(:rdv2021) { create(:rdv, organisation: organisationA, motif: motifA1, starts_at: "2021-01-01 09:00:00 +0200") }

        response 200, "returns policy scoped RDVs filtered with starts_after and starts_before", document: false do
          let(:starts_after) { "2020-01-01" }
          let(:starts_before) { "2020-01-02" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id) }
        end

        response 200, "returns policy scoped RDVs filtered with starts_after only", document: false do
          let(:starts_after) { "2020-01-01" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id, rdv2021.id, rdv.id, rdv_sans_service.id) }
        end

        response 200, "returns policy scoped RDVs filtered with starts_before only", document: false do
          let(:starts_before) { "2020-01-02" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id) }
        end

        response 200, "also works with time params", document: false do
          let(:starts_before) { "2020-01-01 10:00:00" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id) }
        end

        response 200, "also works with time params (with another standard)", document: false do
          let(:starts_before) { "2020-01-01T01:00:00+02:00" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to be_empty }
        end
      end

      response 200, "returns policy scoped RDVs when agent is admin", document: false do
        let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisationA], service: service) }
        let(:access_admin_agent) { api_auth_headers_for_agent(admin_agent) }
        let(:"access-token") { access_admin_agent["access-token"].to_s }
        let(:uid) { access_admin_agent["uid"].to_s }
        let(:client) { access_admin_agent["client"].to_s }

        run_test!

        it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv.id, rdv3.id, rdv_sans_service.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"
    end
  end

  path "/api/v1/rdvs/{rdv_id}/update_status" do
    patch "Mettre à jour le statut d'un rendez-vous" do
      with_oauth_token_authentication

      let!(:agent) { create(:agent, :francis_factice, admin_role_in_organisations: [rdv.organisation]) }

      tags "RDV"
      produces "application/json"
      consumes "application/json"
      operationId "updateRdvStatus"

      humanized_status_values = Rdv.statuses.keys.map do |status|
        "#{status} (#{Rdv.human_attribute_value(:status, status)})"
      end.to_sentence

      description <<~TEXT
        Met à jour le statut d'un rendez-vous passé, pour indiquer s'il a bien eu lieu comme prévu ou s'il a été annulé.
        Les valeurs autorisées pour le statut sont #{humanized_status_values}."
      TEXT

      parameter name: :rdv_id, in: :path, type: :integer, description: "ID du rendez-vous", example: 123
      parameter(
        name: :params, # ce nom n'est pas utilisé, car tous les paramètres sont dans le body de la requête
        in: :body,
        schema: {
          type: :object,
          properties: {
            status: { type: :string, example: "seen" },
          },
          required: %w[status],
        },
        example: { status: "seen" }
      )

      let(:rdv) { create(:rdv, status: :unknown) }
      let(:rdv_id) { rdv.id }

      response 200, "Met à jour et renvoie un rendez-vous" do
        run_test!

        let(:params) do
          { status: "seen" }
        end
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "le statut envoyé n'est pas valide" do
        let(:params) do
          { status: nil }
        end
      end
    end
  end
end
