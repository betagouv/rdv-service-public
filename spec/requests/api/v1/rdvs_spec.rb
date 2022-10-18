require 'swagger_helper'

RSpec.describe 'api/v1/rdvs', type: :request do

  path '/api/v1/organisations/{organisation_id}/rdvs' do
    # You'll want to customize the parameter types...
    parameter name: 'organisation_id', in: :path, type: :string, description: 'organisation_id'

    get('list rdvs') do
      tags "Terminaisons agent"
      response(200, 'successful') do
        let(:organisation_id) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
