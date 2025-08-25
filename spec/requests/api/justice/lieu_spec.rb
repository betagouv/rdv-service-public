RSpec.describe "Api pour Justice.fr" do
  let!(:lieu_with_po) { create(:lieu, id: 1861, organisation:) }
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, organisation:, bookable_by: :everyone) }
  let!(:lieu_without_po) { create(:lieu, id: 2098) }

  before do
    create(:plage_ouverture, lieu: lieu_with_po, motifs: [motif])
  end

  it "renvoie une liste des lieux de justice" do
    get "/api/justice/lieux"

    lieu_without_online_booking = response.parsed_body["lieux"].first.symbolize_keys
    expect(lieu_without_online_booking).to match(
      {
        ee_id: "612f2ebab473e40555dee806",
        reservation_en_ligne: false,
        url: anything,
      }
    )

    lieu_with_online_booking = response.parsed_body["lieux"].last.symbolize_keys
    expect(lieu_with_online_booking).to match(
      {
        ee_id: "612f2ebfb473e40555dee9d4",
        reservation_en_ligne: true,
        url: anything,
      }
    )
  end
end
