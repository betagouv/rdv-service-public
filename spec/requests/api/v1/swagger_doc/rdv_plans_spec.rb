require "swagger_helper"

RSpec.describe "RDV authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/rdv_plans" do
    post "Créer un brouillon de rendez-vous" do
      with_authentication
      description "Permet de créer un brouillon de rendez-vous"

      parameter(
        name: :params, # ce nom n'est pas utilisé, car tous les paramètres sont dans le body de la requête
        in: :body,
        schema: {
          type: :object,
          properties: {
            user: {
              type: :object, properties: {
                first_name: { type: :string },
                last_name: { type: :string },
                email: { type: :string },
                phone_number: { type: :string },
                address: { type: :string },
              },
            },
            return_url: { type: :string },
            dossier_url: { type: :string },
          },
          required: %w[user],
        },
        example: {
          user: {
            first_name: "Francis",
            last_name: "Factice",
            email: "francis.factice@gmail.com",
            phone_number: "0611223344",
            address: "21 rue des Ardennes, 75019 Paris",
          },
          return_url: "https://monsuivisocial.incubateur.anct.gouv.fr/beneficiaires/123",
        }
      )

      with_examples
      produces "application/json"
      consumes "application/json"

      let!(:organisation) { organisations(:default_org) }
      let!(:agent) { create(:agent, email: "agent@example.com", basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 201, "Crée le rdv plan" do
        run_test!

        let(:params) do
          {
            user: {
              first_name: "Francis",
              last_name: "Factice",
              email: "francis.factice@gmail.com",
              phone_number: "0611223344",
              address: "21 rue des Ardennes, 75019 Paris",
            },
          }
        end

        specify do
          rdv_plan = RdvPlan.last
          expect(parsed_response_body.dig("rdv_plan", "url")).to eq "http://www.rdv-service-public-test.localhost/agents/rdv_plans/#{rdv_plan.id}"

          expect(parsed_response_body["rdv_plan"]).to include(
            "user_id" => User.last.id,
            "created_at" => rdv_plan.created_at.to_s,
            "updated_at" => rdv_plan.updated_at.to_s
          )

          expect(rdv_plan.user).to have_attributes(
            first_name: "Francis",
            last_name: "Factice",
            notification_email: "francis.factice@gmail.com",
            phone_number: "0611223344",
            address: "21 rue des Ardennes, 75019 Paris"
          )
          expect(rdv_plan).to have_attributes(
            planning_agent: agent
          )
        end
      end
    end
  end

  path "/api/v1/rdv_plans/{rdv_plan_id}" do
    get "Consulter un rdv plan" do
      with_authentication
      description "Permet de savoir si un rendez-vous a été pris pour ce rdv plan"

      with_examples
      produces "application/json"
      consumes "application/json"
      parameter name: :rdv_plan_id, in: :path, type: :integer, example: 123

      let!(:organisation) { organisations(:default_org) }
      let!(:agent) { create(:agent, email: "agent@example.com", basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Retourne un rdv plan" do
        run_test!

        let(:rdv_plan_id) { rdv_plan.id }
        let!(:rdv_plan) do
          create(:rdv_plan, planning_agent: agent, rdv: rdv)
        end
        let(:rdv) { create(:rdv) }

        specify do
          expect(parsed_response_body.dig("rdv_plan", "url")).to eq "http://www.rdv-service-public-test.localhost/agents/rdv_plans/#{rdv_plan.id}"
          expect(parsed_response_body.dig("rdv_plan", "rdv").symbolize_keys).to include(
            id: rdv.id,
            status: rdv.status,
            location_type: rdv.motif.location_type
          )
          expect(Time.zone.parse(parsed_response_body.dig("rdv_plan", "rdv", "starts_at"))).to be_within(1.second).of(rdv.reload.starts_at)
        end
      end
    end
  end
end
