# frozen_string_literal: true

describe CronJob::UpdatePlageOuverturesExpirationsJob, type: :job do
  let(:now) { Time.zone.parse("20211015 8:50") }

  before do
    travel_to(now)
  end

  context "without recurrence" do
    it "expired past first_day PO" do
      plage_ouverture_exceptionnelle = create(:plage_ouverture, :no_recurrence, first_day: now.to_date - 1.week)
      described_class.perform_now
      expect(plage_ouverture_exceptionnelle.reload.expired_cached).to eq true
    end

    it "not expired futur first_day" do
      plage_ouverture_exceptionnelle = create(:plage_ouverture, :no_recurrence, first_day: now.to_date + 1.week)
      described_class.perform_now
      expect(plage_ouverture_exceptionnelle.reload.expired_cached).to eq false
    end
  end

  context "with recurrence" do
    it "expired past first_day PO" do
      plage_ouverture_reguliere = create(:plage_ouverture, first_day: now - 4.weeks, recurrence: Montrose.every(:week, until: now - 1.week, starts: now - 4.weeks))
      described_class.perform_now
      expect(plage_ouverture_reguliere.reload.expired_cached).to eq true
    end

    it "not expired futur first_day" do
      plage_ouverture_reguliere = create(:plage_ouverture, first_day: now - 4.weeks, recurrence: Montrose.every(:week, until: now + 1.week, starts: now - 4.weeks))
      described_class.perform_now
      expect(plage_ouverture_reguliere.reload.expired_cached).to eq false
    end
  end
end
