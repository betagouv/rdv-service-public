# frozen_string_literal: true

describe "ANTS API: availableTimeSlots" do
  include_context "rdv_mairie_api_authentication"

  let(:lieu1) do
    create(:lieu, organisation: organisation)
  end
  let(:lieu2) do
    create(:lieu, organisation: organisation)
  end
  let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
  let(:motif) { create(:motif, organisation: organisation, default_duration_in_min: 30, motif_category: cni_motif_category) }
  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }

  before do
    travel_to(Date.new(2022, 10, 28))
    create(:plage_ouverture, lieu: lieu1, first_day: Date.new(2022, 11, 1),
                             start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay(10),
                             organisation: organisation, motifs: [motif])
    create(:plage_ouverture, lieu: lieu2, first_day: Date.new(2022, 11, 2),
                             start_time: Tod::TimeOfDay(12), end_time: Tod::TimeOfDay(13),
                             organisation: organisation, motifs: [motif])
  end

  it "returns a list of slots" do
    # L'ANTS nous envoie la requête en utilisant la syntaxe meeting_point_ids=1&meeting_point_ids=2 pour envoyer un tableau d'ids
    # sans crochets donc on encode la querystring d'une manière similaire ici pour reproduire ce comportement
    get "/api/ants/availableTimeSlots?meeting_point_ids=#{lieu1.id}&meeting_point_ids=#{lieu2.id}&start_date=2022-11-01&end_date=2022-11-02&documents_number=1&reason=CNI"

    expect(JSON.parse(response.body)).to eq(
      {
        lieu1.id.to_s => [
          {
            datetime: "2022-11-01T09:00Z",
            callback_url: creneaux_url(starts_at: "2022-11-01 09:00", lieu_id: lieu1.id, motif_id: motif.id),
          },
          {
            datetime: "2022-11-01T09:30Z",
            callback_url: creneaux_url(starts_at: "2022-11-01 09:30", lieu_id: lieu1.id, motif_id: motif.id),
          },
        ],
        lieu2.id.to_s => [
          {
            datetime: "2022-11-02T12:00Z",
            callback_url: creneaux_url(starts_at: "2022-11-02 12:00", lieu_id: lieu2.id, motif_id: motif.id),
          },
          {
            datetime: "2022-11-02T12:30Z",
            callback_url: creneaux_url(starts_at: "2022-11-02 12:30", lieu_id: lieu2.id, motif_id: motif.id),
          },
        ],
      }.with_indifferent_access
    )
  end
end
