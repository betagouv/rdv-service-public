RSpec.describe CronJob::ImportCaldavAbsences do
  it "works" do
    configs = create_list(:caldav_config, 3)
    described_class.new.perform
    expect(enqueued_jobs.pluck("arguments")).to match_array(configs.map { [_1.agent_id] })

    # Les exécutions sont étalées dans le temps, une toutes les 2 secondes
    expect(Time.zone.parse(enqueued_jobs[0]["scheduled_at"])).to be_within(0.1.seconds).of(0.seconds.from_now)
    expect(Time.zone.parse(enqueued_jobs[1]["scheduled_at"])).to be_within(0.1.seconds).of(2.seconds.from_now)
    expect(Time.zone.parse(enqueued_jobs[2]["scheduled_at"])).to be_within(0.1.seconds).of(4.seconds.from_now)
  end
end
