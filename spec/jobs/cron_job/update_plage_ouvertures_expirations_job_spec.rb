describe CronJob::UpdatePlageOuverturesExpirationsJob, type: :job do
  subject do
    described_class.perform_now
  end

  let(:first_day) { Date.today.next_week(:monday) }
  let!(:plage_ouverture_reguliere) { create(:plage_ouverture, first_day: first_day, recurrence: Montrose.every(:week, until: Time.zone.now, starts: first_day)) }
  let!(:plage_ouverture_exceptionnelle) { create(:plage_ouverture, :no_recurrence, first_day: Date.today) }

  context "when plage ouverture are expired" do
    it "calls notification service" do
      travel_to(2.days.from_now)
      expect { subject }.to change(PlageOuverture.where(expired_cached: true), :count).from(0).to(2)
    end
  end

  context "when plage ouverture are not expired" do
    it "calls notification service" do
      expect { subject }.not_to change(PlageOuverture.where(expired_cached: true), :count)
    end
  end
end
