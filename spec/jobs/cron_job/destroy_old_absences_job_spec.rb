RSpec.describe CronJob::DestroyOldAbsencesJob do
  let(:now) { Time.zone.parse("20220405 10:00") }

  before { travel_to(now) }

  it "Destroy exceptional absences closed since 2 years" do
    absence_exceptionelle_closed_since_2_years = create(:absence, first_day: now - 2.years - 3.days, recurrence: nil)

    described_class.new.perform

    expect(Absence.all).not_to include(absence_exceptionelle_closed_since_2_years)
  end

  it "keep exceptional absence closed since 10 days" do
    absence_exceptionelle_closed_since_10_days = create(:absence, first_day: now - 10.days, recurrence: nil)

    described_class.new.perform

    expect(Absence.all).to include(absence_exceptionelle_closed_since_10_days)
  end

  it "destroy recurrence absence closed since 2 years" do
    absence_recurrence_closed_since_2_years = create(:absence, first_day: now - 3.years, recurrence: Montrose.every(:week, starts: now - 3.years, until: now - 2.years - 3.days))

    described_class.new.perform

    expect(Absence.all).not_to include(absence_recurrence_closed_since_2_years)
  end

  it "keep recurrence absence closed since 10 days" do
    absence_recurrence_closed_since_10_days = create(:absence, first_day: now - 3.years, recurrence: Montrose.every(:week, starts: now - 3.years, until: now - 10.days))

    described_class.new.perform

    expect(Absence.all).to include(absence_recurrence_closed_since_10_days)
  end

  it "keep recurrence absence still open" do
    absence_recurrence_not_closed = create(:absence, first_day: now - 3.years, recurrence: Montrose.every(:week, starts: now - 3.years, until: nil))

    described_class.new.perform

    expect(Absence.all).to include(absence_recurrence_not_closed)
  end

  context "multi-day absence" do
    it "keeps it when finished since 18 month" do
      absence = create(:absence, first_day: now - 2.years - 3.days, end_day: now - 18.months, recurrence: nil)
      described_class.new.perform
      expect(Absence.all).to include(absence)
    end

    it "destroys it when finished since more than 2 years" do
      absence = create(:absence, first_day: now - 2.years - 3.days, end_day: now - 2.years - 1.day, recurrence: nil)
      described_class.new.perform
      expect(Absence.all).not_to include(absence)
    end
  end

  it "sends webhooks events" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    create(:absence, first_day: now - 2.years - 3.days, recurrence: nil, agent:)
    create(:webhook_endpoint, organisation:, subscriptions: ["absence"])

    described_class.new.perform

    expect(enqueued_jobs.last["job_class"]).to eq("WebhookJob")
  end
end
