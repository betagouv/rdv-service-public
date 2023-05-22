# frozen_string_literal: true

describe SlotBuilder::BusyTime, type: :service do
  let(:monday) { Time.zone.parse("20211025 10:00") }
  let(:range) { Time.zone.parse("2021-10-26 8:00")..Time.zone.parse("2021-10-29 12:00") }
  let(:plage_ouverture) { create(:plage_ouverture) }

  before { travel_to(monday) }

  it "returns empty busy times without RDV or absence" do
    expect(described_class.busy_times_for(range, plage_ouverture)).to eq([])
  end

  context "with a RDV" do
    it "returns BusyTime object in array with a RDV" do
      create(:rdv, agents: [plage_ouverture.agent], starts_at: Time.zone.parse("20211027 9:00"))
      expect(described_class.busy_times_for(range, plage_ouverture).first).to be_a(described_class)
    end

    it "returns BusyTime that starts_at as RDV starts_at" do
      create(:rdv, agents: [plage_ouverture.agent], starts_at: Time.zone.parse("20211027 9:00"))
      expect(described_class.busy_times_for(range, plage_ouverture).first.starts_at).to eq(Time.zone.parse("20211027 9:00"))
    end

    it "returns BusyTime that ends_at as RDV ends_at" do
      create(:rdv, agents: [plage_ouverture.agent], starts_at: Time.zone.parse("20211027 9:00"), ends_at: Time.zone.parse("20211027 9:40"))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211027 9:40"))
    end
  end

  context "with an absence without recurrence" do
    it "returns BusyTime starts_at as absence first_day and start_time" do
      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9))
      expect(described_class.busy_times_for(range, plage_ouverture).first.starts_at).to eq(Time.zone.parse("20211027 9:00"))
    end

    it "returns BusyTime ends_at as absence first_day and end_time when end_day is nil" do
      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_day: nil,
                       end_time: Tod::TimeOfDay.new(9, 40))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211027 9:40"))
    end

    it "returns BusyTime ends_at as absence end_day and end_time" do
      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9),
                       end_day: Date.new(2021, 10, 28), end_time: Tod::TimeOfDay.new(12))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211028 12"))
    end

    it "dont return BusyTime if absence is out of range" do
      range = Time.zone.parse("2021-10-26 9:00")..Time.zone.parse("2021-10-29 11:00")

      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 29), start_time: Tod::TimeOfDay.new(14),
                       end_day: Date.new(2021, 10, 29), end_time: Tod::TimeOfDay.new(15))
      expect(described_class.busy_times_for(range, plage_ouverture)).to be_empty
    end
  end

  context "with an absence with recurrence" do
    it "returns starts_at first occurrence in range" do
      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 19), start_time: Tod::TimeOfDay.new(9),
                       recurrence: Montrose.every(:week, on: ["tuesday"], starts: Time.zone.parse("20211019 9:00"), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture).first.starts_at).to eq(Time.zone.parse("20211026 9:00"))
    end

    it "returns ends_at occurrence in range" do
      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 19), start_time: Tod::TimeOfDay.new(9),
                       end_time: Tod::TimeOfDay.new(9, 45), recurrence: Montrose.every(:week, on: ["tuesday"], starts: Time.zone.parse("20211019 9:00"), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211026 9:45"))
    end

    it "returns a busy_time for each occurrence in range" do
      create(:absence,
             agent: plage_ouverture.agent,
             first_day: Date.new(2021, 10, 19),
             start_time: Tod::TimeOfDay.new(9),
             end_time: Tod::TimeOfDay.new(9, 45),
             recurrence: Montrose.every(:week, on: %w[tuesday friday], starts: Time.zone.parse("20211019 9:00"), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture).map(&:ends_at)).to eq([Time.zone.parse("20211026 9:45"), Time.zone.parse("20211029 9:45")])
    end

    it "dont return BusyTime if absence occurrence is out of range" do
      range = Time.zone.parse("2021-10-29 9:00")..Time.zone.parse("2021-10-29 11:00")

      create(:absence, agent: plage_ouverture.agent, first_day: Date.new(2021, 10, 22),
                       start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15),
                       recurrence: Montrose.every(:week, on: %w[tuesday friday], starts: Date.new(2021, 10, 22), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture)).to be_empty
    end
  end

  context "with an off_day in range" do
    context "with a range on a single day" do
      it "returns off_day from beginning of day to end of day" do
        christmas_morning = Time.zone.parse("2024-12-25 8:00")..Time.zone.parse("2024-12-25 12:00")
        busy_time = described_class.busy_times_for(christmas_morning, plage_ouverture).first
        expect(busy_time.starts_at).to eq(Time.zone.parse("2024-12-25 0:00"))
        expect(busy_time.ends_at).to be_within(1.second).of(Time.zone.parse("2024-12-25 23:59:59"))
      end

      it "returns off_day that in given range only" do
        regular_monday_morning =  Time.zone.parse("2021-12-13 8:00")..Time.zone.parse("2021-12-13 12:00")
        expect(described_class.busy_times_for(regular_monday_morning, plage_ouverture)).to be_empty
      end
    end

    context "with a range spanning several days" do
      it "returns off_day from beginning of day to end of day" do
        christmas_week = Time.zone.parse("2024-12-20 8:00")..Time.zone.parse("2024-12-26 12:00")
        busy_time = described_class.busy_times_for(christmas_week, plage_ouverture).first
        expect(busy_time.starts_at).to eq(Time.zone.parse("2024-12-25 0:00"))
        expect(busy_time.ends_at).to be_within(1.second).of(Time.zone.parse("2024-12-25 23:59:59"))
      end

      it "returns off_day that in given range only" do
        all_work_week = Time.zone.parse("2021-12-13 8:00")..Time.zone.parse("2021-12-19 12:00")
        expect(described_class.busy_times_for(all_work_week, plage_ouverture)).to be_empty
      end
    end
  end
end
