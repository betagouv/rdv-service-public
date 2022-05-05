# frozen_string_literal: true

describe CronJob::DestroyOldPlageOuvertureJob do
  it "Destroy exceptional po closed since 2 years" do
    now = Time.zone.parse("20220405 10:00")
    travel_to(now)
    po_exceptionelle_closed_since_2_years = create(:plage_ouverture, first_day: now - 2.years, recurrence: nil)

    described_class.new.perform

    expect(PlageOuverture.all).not_to include(po_exceptionelle_closed_since_2_years)
  end

  it "keep exceptional po closed since 10 days" do
    now = Time.zone.parse("20220405 10:00")
    travel_to(now)
    po_exceptionelle_closed_since_10_days = create(:plage_ouverture, first_day: now - 10.days, recurrence: nil)

    described_class.new.perform

    expect(PlageOuverture.all).to include(po_exceptionelle_closed_since_10_days)
  end

  it "destroy recurrence po closed since 2 years" do
    now = Time.zone.parse("20220405 10:00")
    travel_to(now)
    po_recurrence_closed_since_2_years = create(:plage_ouverture, first_day: now - 3.years, recurrence: Montrose.every(:week, starts: now - 3.years, until: now - 2.years))

    described_class.new.perform

    expect(PlageOuverture.all).not_to include(po_recurrence_closed_since_2_years)
  end

  it "keep recurrence po closed since 10 days" do
    now = Time.zone.parse("20220405 10:00")
    travel_to(now)
    po_recurrence_closed_since_10_days = create(:plage_ouverture, first_day: now - 3.years, recurrence: Montrose.every(:week, starts: now - 3.years, until: now - 10.days))

    described_class.new.perform

    expect(PlageOuverture.all).to include(po_recurrence_closed_since_10_days)
  end

  it "keep recurrence po still open" do
    now = Time.zone.parse("20220405 10:00")
    travel_to(now)
    po_recurrence_not_closed = create(:plage_ouverture, first_day: now - 3.years, recurrence: Montrose.every(:week, starts: now - 3.years, until: nil))

    described_class.new.perform

    expect(PlageOuverture.all).to include(po_recurrence_not_closed)
  end
end
