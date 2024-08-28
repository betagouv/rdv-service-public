RSpec.describe PlageOuvertureOverlap do
  let(:organisation) { build(:organisation) }
  let(:agent) { build(:agent, organisations: [organisation]) }
  let(:monday) { Date.new(2021, 9, 20) }

  before do
    travel_to(monday)
  end

  def build_po(first_day, start_hour, end_hour, recurrence = nil)
    build(
      :plage_ouverture,
      agent: agent,
      first_day: first_day,
      recurrence_ends_at: (recurrence ? recurrence.ends_at : nil),
      start_time: Tod::TimeOfDay.new(start_hour),
      end_time: Tod::TimeOfDay.new(end_hour),
      **(recurrence ? { recurrence: recurrence.to_json } : {})
    )
  end

  shared_examples "plage ouvertures overlap" do
    it "overlaps" do
      expect(described_class.new(po1, po2).exists?).to be true
      expect(described_class.new(po2, po1).exists?).to be true
    end
  end

  shared_examples "plage ouvertures do not overlap" do
    it "does not overlap" do
      expect(described_class.new(po1, po2).exists?).to be false
      expect(described_class.new(po2, po1).exists?).to be false
    end
  end

  # both exceptionnelles

  context "po1 and po2 exceptionnelles, exactly overlapping" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday, 14, 18) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 exceptionnelles, included in other" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday, 15, 16) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 exceptionnelles, includes other" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday, 8, 20) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 exceptionnelles, partially overlapping start" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday, 8, 16) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 exceptionnelles, partially overlapping end" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday, 16, 20) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 exceptionnelles, non overlapping same day" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday, 8, 12) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 exceptionnelles, non overlapping other day" do
    let(:po1) { build_po(monday, 14, 18) }
    let(:po2) { build_po(monday + 1.day, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  # po1 recurring, po2 exceptionnelle

  context "po1 recurring without end date, po2 exceptionnelle before recurring" do
    let(:po1) { build_po(monday, 14, 18, Montrose.weekly.on(%i[monday tuesday])) }
    let(:po2) { build_po(monday - 7.days, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring without end date, po2 exceptionnelle on other day same week" do
    let(:po1) { build_po(monday, 14, 18, Montrose.weekly.on(%i[monday tuesday])) }
    let(:po2) { build_po(monday + 3.days, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring without end date, po2 exceptionnelle on other day next week" do
    let(:po1) { build_po(monday, 14, 18, Montrose.weekly.on(%i[monday tuesday])) }
    let(:po2) { build_po(monday + 1.week + 3.days, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring without end date, po2 exceptionnelle on same day but times don't overlap" do
    let(:po1) { build_po(monday, 14, 18, Montrose.weekly.on(%i[monday tuesday])) }
    let(:po2) { build_po(monday + 8.days, 8, 10) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring without end date, po2 exceptionnelle on same day and times overlap" do
    let(:po1) { build_po(monday, 14, 18, Montrose.weekly.on(%i[monday tuesday])) }
    let(:po2) { build_po(monday + 8.days, 15, 20) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 recurring every 3 weeks without end date, po2 exceptionnelle on same week day 6 weeks after" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(3.weeks, starts: monday).on(%i[monday tuesday])) }
    let(:po2) { build_po(monday + 6.weeks, 14, 18) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 recurring every 3 weeks without end date, po2 exceptionnelle on same week day 4 weeks after" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(3.weeks, on: %i[monday tuesday], starts: monday)) }
    let(:po2) { build_po(monday + 4.weeks, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring with end date, po2 exceptionnelle before recurring" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday - 7.days, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring with end date, po2 exceptionnelle same weekday before po1 end date" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 7.days, 14, 18) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 recurring with end date, po2 exceptionnelle other weekday before po1 end date" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday - 10.days, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring with end date, po2 exceptionnelle same weekday after po1 end date" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 4.weeks, 14, 18) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  ## both recurring

  context "po1 and po2 recurring without end date, different weekdays" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday)) }
    let(:po2) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[wednesday thursday], starts: monday)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring without end date, overlapping weekdays" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday)) }
    let(:po2) { build_po(monday + 7.days, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], starts: monday + 7.days)) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 recurring without end date, overlapping weekdays but different times" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday)) }
    let(:po2) { build_po(monday, 10, 12, Montrose.every(:week, on: %i[tuesday wednesday], starts: monday)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring without end date, non-overlapping alternative weeks" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], interval: 2, starts: monday)) }
    let(:po2) { build_po(monday + 1.week, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], interval: 2, starts: monday + 1.week)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring without end date, overlapping weeks" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], interval: 2, starts: monday)) }
    let(:po2) { build_po(monday + 1.week, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], interval: 3, starts: monday + 1.week)) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 recurring with end date, po2 recurring without end date, po2 starts before po1 ends, with weekdays overlap" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 7.days, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], starts: monday + 7.days)) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 recurring with end date, po2 recurring without end date, po2 starts before po1 ends, without weekdays overlap" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 7.days, 14, 18, Montrose.every(:week, on: %i[wednesday thursday], starts: monday + 7.days)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 recurring with end date, po2 recurring without end date, po2 starts after po1 ends" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 4.weeks, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], starts: monday + 4.weeks)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring with end date, overlap" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 1.week, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], starts: monday + 1.week, until: monday + 5.weeks)) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 recurring with end date, non-overlapping alternative weeks" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], interval: 2, starts: monday, until: monday + 10.weeks)) }
    let(:po2) { build_po(monday + 1.week, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], interval: 2, starts: monday + 1.week, until: monday + 10.weeks)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring with end date, overlapping weeks" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], interval: 2, starts: monday, until: monday + 10.weeks)) }
    let(:po2) { build_po(monday + 1.week, 14, 18, Montrose.every(:week, on: %i[tuesday wednesday], interval: 3, starts: monday + 1.week, until: monday + 10.weeks)) }

    it_behaves_like "plage ouvertures overlap"
  end

  context "po1 and po2 recurring with end date, po2 starts after po1 ends" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 4.weeks, 10, 12, Montrose.every(:week, on: %i[tuesday wednesday], starts: monday + 4.weeks, until: monday + 6.weeks)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring with end date, overlap but weekdays mismatch" do
    let(:po1) { build_po(monday, 14, 18, Montrose.every(:week, on: %i[monday tuesday], starts: monday, until: monday + 3.weeks)) }
    let(:po2) { build_po(monday + 4.weeks, 10, 12, Montrose.every(:week, on: %i[wednesday thursday], starts: monday + 4.weeks, until: monday + 6.weeks)) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring monthly, same time and day but different week" do
    let(:po1) { build_po(monday, 10, 12, Montrose.every(:month, day: { 1 => 1 })) }
    let(:po2) { build_po(monday, 10, 12, Montrose.every(:month, day: { 1 => 2 })) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 and po2 recurring monthly, same time and week but different days" do
    let(:po1) { build_po(monday, 10, 12, Montrose.every(:month, day: { 1 => 1 })) }
    let(:po2) { build_po(monday, 10, 12, Montrose.every(:month, day: { 2 => 2 })) }

    it_behaves_like "plage ouvertures do not overlap"
  end

  context "po1 is set to recurring but days are not set" do
    let(:po1) { build_po(monday, 10, 12, Montrose.every(:week, day: nil)) }
    let(:po2) { build_po(monday, 10, 12, Montrose.every(:week, day: { 2 => 2 })) }

    it_behaves_like "plage ouvertures do not overlap"
  end
end
