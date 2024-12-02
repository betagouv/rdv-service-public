RSpec.describe CronJob::UpdateExpirationsJob, type: :job do
  let(:now) { Time.zone.parse("20211015 8:50") }

  before do
    travel_to(now)
  end

  context "PO without recurrence" do
    it "expired past first_day" do
      plage_ouverture_exceptionnelle = create(:plage_ouverture, :no_recurrence, first_day: now.to_date - 1.week)
      described_class.perform_now
      expect(plage_ouverture_exceptionnelle.reload.expired_cached).to be true
    end

    it "not expired futur first_day" do
      plage_ouverture_exceptionnelle = create(:plage_ouverture, :no_recurrence, first_day: now.to_date + 1.week)
      described_class.perform_now
      expect(plage_ouverture_exceptionnelle.reload.expired_cached).to be false
    end
  end

  context "PO with recurrence" do
    it "expired past first_day" do
      plage_ouverture_reguliere = create(:plage_ouverture, first_day: now - 4.weeks, recurrence: Montrose.every(:week, until: now - 1.week, starts: now - 4.weeks))
      described_class.perform_now
      expect(plage_ouverture_reguliere.reload.expired_cached).to be true
    end

    it "not expired futur first_day" do
      plage_ouverture_reguliere = create(:plage_ouverture, first_day: now - 4.weeks, recurrence: Montrose.every(:week, until: now + 1.week, starts: now - 4.weeks))
      described_class.perform_now
      expect(plage_ouverture_reguliere.reload.expired_cached).to be false
    end
  end

  context "Absence without recurrence" do
    it "expired past first_day" do
      absence_exceptionnelle = create(:absence, :no_recurrence, first_day: now.to_date - 1.week)
      described_class.perform_now
      expect(absence_exceptionnelle.reload.expired_cached).to be true
    end

    it "not expired futur first_day" do
      absence_exceptionnelle = create(:absence, :no_recurrence, first_day: now.to_date + 1.week)
      described_class.perform_now
      expect(absence_exceptionnelle.reload.expired_cached).to be false
    end
  end

  context "Absence with recurrence" do
    it "expired past first_day" do
      absence_reguliere = create(:absence, first_day: now - 4.weeks, recurrence: Montrose.every(:week, until: now - 1.week, starts: now - 4.weeks))
      described_class.perform_now
      expect(absence_reguliere.reload.expired_cached).to be true
    end

    it "not expired futur first_day" do
      absence_reguliere = create(:absence, first_day: now - 4.weeks, recurrence: Montrose.every(:week, until: now + 1.week, starts: now - 4.weeks))
      described_class.perform_now
      expect(absence_reguliere.reload.expired_cached).to be false
    end
  end
end
