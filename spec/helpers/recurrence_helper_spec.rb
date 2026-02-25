RSpec.describe RecurrenceHelper do
  let(:now) { Time.zone.parse("2021-12-23 09:00") }

  before do
    travel_to(now)
  end

  describe "#display_recurrence" do
    it "with a weekly recurrence" do
      plage_ouverture = build(:plage_ouverture, :weekly_on_monday)
      expect(display_recurrence(plage_ouverture)).to eq(["Tous les lundis", "de 08:00 à 12:00", "à partir du mardi 28 décembre"])
    end

    it "with a weekly recurrence on wednesday" do
      plage_ouverture = build(:plage_ouverture, recurrence: Montrose.every(:week, on: ["wednesday"], interval: 1))
      expect(display_recurrence(plage_ouverture)).to eq(["Tous les mercredis", "de 08:00 à 12:00", "à partir du mardi 28 décembre"])
    end

    it "with a recurrence every other week" do
      plage_ouverture = build(:plage_ouverture, :every_two_weeks)
      expect(display_recurrence(plage_ouverture)).to eq(["Toutes les 2 semaines, les lundis", "de 08:00 à 12:00", "à partir du mardi 28 décembre"])
    end

    it "with a monthly recurrence" do
      plage_ouverture = build(:plage_ouverture, recurrence: Montrose.every(:month, day: { 3 => [2] }))
      expect(display_recurrence(plage_ouverture)).to eq(["Tous les mois, le 2ème mercredi", "de 08:00 à 12:00", "à partir du mardi 28 décembre"])
    end

    it "with a secondary time interval" do
      plage_ouverture = build(:plage_ouverture, recurrence: Montrose.every(:week), secondary_start_time: "14:00", secondary_end_time: "17:45")
      expect(display_recurrence(plage_ouverture)).to eq(["Toutes les semaines, le mardi", "de 08:00 à 12:00 et de 14:00 à 17:45", "à partir du mardi 28 décembre"])
    end
  end

  describe "#occurrence_text" do
    it "returns occurrence text" do
      plage_ouverture = build(:plage_ouverture, recurrence: Montrose.every(:week))
      expect(occurrence_text(plage_ouverture)).to eq("Toutes les semaines, le mardi de 08:00 à 12:00 à partir du mardi 28 décembre")
    end

    it "returns" do
      plage_ouverture = build(:plage_ouverture)
      expect(occurrence_text(plage_ouverture)).to eq("mardi 28 décembre de 08:00 à 12:00")
    end
  end

  describe "#exceptionnelle_tag" do
    it "return exceptionnelle badge without recurrence" do
      plage_ouverture = build(:plage_ouverture)
      expect(exceptionnelle_tag(plage_ouverture)).to eq(%(<span class="fr-badge fr-badge--sm fr-badge--green-archipel">Exceptionnelle</span>))
    end

    it "return nil with recurrence" do
      plage_ouverture = build(:plage_ouverture, recurrence: Montrose.every(:week))
      expect(exceptionnelle_tag(plage_ouverture)).to be_nil
    end
  end
end
