# frozen_string_literal: true

describe "ANTS API: availableTimeSlots" do
  around do |example|
    previous_auth_token = ENV["ANTS_API_AUTH_TOKEN"]

    ENV["ANTS_API_AUTH_TOKEN"] = "fake_ants_api_auth_token"

    example.run

    ENV["ANTS_API_AUTH_TOKEN"] = previous_auth_token
  end

  let(:lieu_1) do
    create(:lieu, organisation: organisation)
  end
  let(:lieu_2) do
    create(:lieu, organisation: organisation)
  end
  let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
  let(:motif) { create(:motif, organisation: organisation, default_duration_in_min: 30) }

  before do
    travel_to(Date.new(2022, 10, 28))
    create(:plage_ouverture, lieu: lieu_1, first_day: Date.new(2022, 11, 1),
                             start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay(11),
                             organisation: organisation, motifs: [motif])
    create(:plage_ouverture, lieu: lieu_2, first_day: Date.new(2022, 11, 2),
                             start_time: Tod::TimeOfDay(12), end_time: Tod::TimeOfDay(13),
                             organisation: organisation, motifs: [motif])
  end

  it "returns a list of slots" do
    get "/api/ants/availableTimeSlots", params: {
      meeting_point_ids: [lieu_1.id, lieu_2.id],
      start_date: "2022-11-01",
      end_date: "2022-11-02",
      reason: "CNI",
      documents_number: 1,
    }, headers: { "X-HUB-RDV-AUTH-TOKEN" => "fake_ants_api_auth_token" }

    expect(JSON.parse(response.body)).to eq(
      {
        lieu_1.id.to_s => [
          {
            datetime: "2022-11-01T09:00Z",
          },
          {
            datetime: "2022-11-01T09:30Z",
          },
          {
            datetime: "2022-11-01T10:00Z",
          },
          {
            datetime: "2022-11-01T10:30Z",
          },
        ],
        lieu_2.id.to_s => [
          {
            datetime: "2022-11-02T12:00Z",
          },
          {
            datetime: "2022-11-02T12:30Z",
          }
        ],
      }.with_indifferent_access,
    )
  end
end
