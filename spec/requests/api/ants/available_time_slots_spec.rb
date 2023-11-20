describe "ANTS API: availableTimeSlots" do
  include_context "rdv_mairie_api_authentication"
  stub_sentry_events

  let(:lieu1) do
    create(:lieu, organisation: organisation)
  end
  let(:lieu2) do
    create(:lieu, organisation: organisation2)
  end
  let(:mairies_territory) { create(:territory, :mairies) }
  let(:organisation) { create(:organisation, territory: mairies_territory) }
  let(:organisation2) { create(:organisation, territory: mairies_territory) }
  let(:motif) { create(:motif, organisation: organisation, default_duration_in_min: 30, motif_category: cni_motif_category) }
  let(:motif2) { create(:motif, organisation: organisation2, default_duration_in_min: 30, motif_category: cni_motif_category) }
  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }

  before do
    travel_to(Date.new(2022, 10, 28))
    create(:plage_ouverture, lieu: lieu1, first_day: Date.new(2022, 11, 1),
                             start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay(10),
                             organisation: organisation, motifs: [motif])
    create(:plage_ouverture, lieu: lieu2, first_day: Date.new(2022, 11, 2),
                             start_time: Tod::TimeOfDay(12), end_time: Tod::TimeOfDay(13),
                             organisation: organisation2, motifs: [motif2])
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
            callback_url: creneaux_url(starts_at: "2022-11-01 09:00", lieu_id: lieu1.id, motif_id: motif.id, public_link_organisation_id: organisation.id, duration: 30),
          },
          {
            datetime: "2022-11-01T09:30Z",
            callback_url: creneaux_url(starts_at: "2022-11-01 09:30", lieu_id: lieu1.id, motif_id: motif.id, public_link_organisation_id: organisation.id, duration: 30),
          },
        ],
        lieu2.id.to_s => [
          {
            datetime: "2022-11-02T12:00Z",
            callback_url: creneaux_url(starts_at: "2022-11-02 12:00", lieu_id: lieu2.id, motif_id: motif2.id, public_link_organisation_id: organisation2.id, duration: 30),
          },
          {
            datetime: "2022-11-02T12:30Z",
            callback_url: creneaux_url(starts_at: "2022-11-02 12:30", lieu_id: lieu2.id, motif_id: motif2.id, public_link_organisation_id: organisation2.id, duration: 30),
          },
        ],
      }.with_indifferent_access
    )
  end

  context "there's more than 1 participant" do
    let(:participants_count) { 2 }

    it "returns slots with a duration matching the number of participants" do
      get "/api/ants/availableTimeSlots?meeting_point_ids=#{lieu1.id}&meeting_point_ids=#{lieu2.id}&start_date=2022-11-01&end_date=2022-11-02&documents_number=#{participants_count}&reason=CNI"

      expect(JSON.parse(response.body)).to eq(
        {
          lieu1.id.to_s => [
            {
              datetime: "2022-11-01T09:00Z",
              callback_url: creneaux_url(starts_at: "2022-11-01 09:00", lieu_id: lieu1.id, motif_id: motif.id, public_link_organisation_id: organisation.id, duration: 60),
            },
          ],
          lieu2.id.to_s => [
            {
              datetime: "2022-11-02T12:00Z",
              callback_url: creneaux_url(starts_at: "2022-11-02 12:00", lieu_id: lieu2.id, motif_id: motif2.id, public_link_organisation_id: organisation2.id, duration: 60),
            },
          ],
        }.with_indifferent_access
      )
    end
  end

  context "Responds with an Error" do
    before do
      # Delete motifs and motifs category to create an error
      organisation.motifs.destroy_all
      MotifCategory.destroy_all
    end

    xit "adds crumb with request details to Sentry" do
      expect do
        get "/api/ants/availableTimeSlots?meeting_point_ids=#{lieu1.id}&meeting_point_ids=#{lieu2.id}&start_date=2022-11-01&end_date=2022-11-02&documents_number=1&reason=CNI"
      end.to raise_error(NoMethodError)

      crumb = sentry_events.last.breadcrumbs.compact.first
      expect(crumb.message).to eq("ANTS API Request details")
      expect(crumb.data[:params]).to match(hash_including({ "start_date" => "2022-11-01", "end_date" => "2022-11-02", "documents_number" => "1", "reason" => "CNI", "controller" => "api/ants/editor",
                                                            "action" => "available_time_slots", }))
    end
  end
end
