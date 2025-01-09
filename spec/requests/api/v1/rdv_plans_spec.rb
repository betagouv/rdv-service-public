require "swagger_helper"

RSpec.describe "RDV authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/rdv_plans" do
    post "Créer un plan" do
    end
  end
end
