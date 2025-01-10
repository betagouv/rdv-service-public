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
              },
            },
            return_url: { type: :string },
            lieux: {
              type: :array,
            },
          },
          required: %w[user return_url],
        },
        example: {
          user: {
            first_name: "Francis",
            last_name: "Factice",
            email: "francis.factice@gmail.com",
            phone_number: "0611223344",
          },
          return_url: "https://monsuivisocial.incubateur.anct.gouv.fr/beneficiaires/123",
        }
      )

      with_examples
      produces "application/json"
      consumes "application/json"

      let(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, id: 12, email: "agent@example.com", basic_role_in_organisations: [organisation]) }
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
            },
            return_url: "https://https://monsuivisocial.incubateur.anct.gouv.fr/beneficiaires/123",
          }
        end

        specify do
          rdv_plan = RdvPlan.last
          expect(parsed_response_body.dig("rdv_plan", "url")).to eq "http://localhost:3000/agents/rdv_plans/#{rdv_plan.id}/edit_starts_at"
          expect(rdv_plan.user).to have_attributes(
            first_name: "Francis",
            last_name: "Factice",
            email: "francis.factice@gmail.com",
            phone_number: "0611223344"
          )
          expect(rdv_plan).to have_attributes(
            planning_agent: agent,
            return_url: "https://https://monsuivisocial.incubateur.anct.gouv.fr/beneficiaires/123"
          )
        end
      end
    end
  end
end
