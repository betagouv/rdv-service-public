# frozen_string_literal: true

describe "ANTS API : availableTimeSlots endpoint" do
  around do |example|
    previous_auth_token = ENV["ANTS_API_AUTH_TOKEN"]

    ENV["ANTS_API_AUTH_TOKEN"] = "fake_ants_api_auth_token"

    example.run

    ENV["ANTS_API_AUTH_TOKEN"] = previous_auth_token
  end

  let(:lieu) do
    create(:lieu, organisation: organisation)
  end
  let(:organisation) { create(:organisation, verticale: :rdv_mairie) }

  it "returns a list of slots" do
    get "/api/ants/availableTimeSlots", params: {
      meeting_point_ids: [lieu.id],
      start_date: "2022-11-01",
      end_date: "2022-11-01",
      reason: "CNI",
      documents_number: 1,
    }

    expect(JSON.parse(response.body)).to eq { lieu_id => [] }
  end
end
