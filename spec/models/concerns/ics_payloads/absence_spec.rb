RSpec.describe IcsPayloads::Absence do
  describe "#payload" do
    %i[name starts_at recurrence ical_uid ends_at].each do |key|
      it "return an hash with key #{key}" do
        absence = build(:absence)
        expect(absence.payload).to have_key(key)
      end
    end

    describe ":action" do
      it "return an hash with key action key and value" do
        absence = build(:absence)
        expect(absence.payload(:create)[:action]).to eq(:create)
      end
    end

    describe ":name" do
      let(:absence) { build(:absence, title: "something", start_time: Time.zone.parse("12h30"), first_day: Date.new(2020, 11, 13)) }

      it { expect(absence.payload[:name]).to eq("absence-something-2020-11-13-12-30-00-0100.ics") }
    end

    describe ":starts_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:absence) { build(:absence, start_time: starts_at, first_day: starts_at.to_date) }

      it { expect(absence.payload[:starts_at]).to eq(starts_at) }
    end

    describe ":recurrence" do
      let(:absence) { build(:absence, recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_json) }

      it { expect(absence.payload[:recurrence]).to eq("FREQ=WEEKLY;BYDAY=WE;") }
    end

    describe ":ical_uid" do
      let(:absence) { create(:absence) }

      it { expect(absence.payload[:ical_uid]).to eq("absence_#{absence.id}@RDV Solidarités") }
    end

    describe ":ends_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:absence) { build(:absence, end_time: starts_at + 5.hours, first_day: starts_at.to_date) }

      it { expect(absence.payload[:ends_at]).to eq(starts_at + 5.hours) }
    end
  end
end
