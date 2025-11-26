RSpec.describe CronJob::UpdateRdvCalculatorIndexJob do
  let(:future_rdv) { create(:rdv, starts_at: 3.days.from_now) }
  let(:past_rdv) { create(:rdv, starts_at: 1.day.ago) }

  before do
    # On simule le fait que le rendez-vous était marqué comme étant dans le futur hier, mais est dans le passé aujourd'hui
    past_rdv.agents_rdvs.first.update(readonly_busy_in_the_future: true)
  end

  it "updates the AgentsRdv in the past, but not those in the future" do
    expect do
      described_class.new.perform
    end.to change { past_rdv.agents_rdvs.first.reload.readonly_busy_in_the_future }.from(true).to(false)

    expect(future_rdv.agents_rdvs.first.reload.readonly_busy_in_the_future).to be_truthy
  end
end
