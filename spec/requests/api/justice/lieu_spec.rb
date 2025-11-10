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

  describe "feature flag pour indiquer si la prise de rendez-vous doit être mise en avant sur l'application" do
    context "sans la variable d'env pour le feature flag" do
      it "n'indique pas d'activer la feature" do
        get "/api/justice/lieux"
        expect(parsed_response_body["display_feature"]).to be false
      end
    end

    context "avec la variable d'env" do
      stub_env_with(ENABLE_JUSTICE_FR_FEATURE_FLAG: "true")

      it "indique d'activer la feature" do
        get "/api/justice/lieux"
        expect(parsed_response_body["display_feature"]).to be true
      end
    end
  end
end
