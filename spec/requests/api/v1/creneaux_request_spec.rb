# frozen_string_literal: true

describe "api/v1/creneaux requests", type: :request do
  subject(:run_request) { get api_v1_creneaux_path(params), headers: api_auth_headers_for_agent(agent_for_auth) }

  let!(:organisation) { create(:organisation) }
  let!(:agent_for_auth) { create(:agent, organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation: organisation, default_duration_in_min: 30) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:params) do
    {
      organisation_id: organisation.id,
      motif_id: motif.id,
    }
  end

  context "when no agent declared a creneau" do
    it "returns an empty array" do
      run_request
      expected_body = {
        "creneaux" => [],
        "meta" => {
          "current_page" => 1,
          "next_page" => nil,
          "prev_page" => nil,
          "total_count" => 0,
          "total_pages" => 1,
        },
      }
      expect(JSON.parse(response.body)).to eq(expected_body)
    end
  end

  context "when there are creneaux" do
    before { travel_to(Time.zone.parse("2022-09-30 14:00")) }

    let!(:agent_with_creneau) { create(:agent, organisations: [organisation]) }
    let!(:plage_ouverture) do
      create(
        :plage_ouverture,
        motifs: [motif],
        agent: agent_with_creneau,
        lieu: lieu,
        first_day: Time.zone.parse("2022-10-03 14:00"),
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(12)
      )
    end

    it "returns the list" do
      run_request
      response_body = JSON.parse(response.body)
      expected_occurrences = [
        "2022-10-03 09:00:00 +0200",
        "2022-10-03 09:30:00 +0200",
        "2022-10-03 10:00:00 +0200",
        "2022-10-03 10:30:00 +0200",
        "2022-10-03 11:00:00 +0200",
        "2022-10-03 11:30:00 +0200",
      ]
      expect(response_body["creneaux"].pluck("starts_at")).to eq(expected_occurrences)

      expected_meta = {
        "current_page" => 1,
        "next_page" => nil,
        "prev_page" => nil,
        "total_count" => 6,
        "total_pages" => 1,
      }
      expect(response_body["meta"]).to eq(expected_meta)
    end
  end
end
