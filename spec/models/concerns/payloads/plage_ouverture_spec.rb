RSpec.describe Payloads::PlageOuverture do
  describe "#payload" do
    %i[name starts_at recurrence ical_uid ends_at].each do |key|
      it "return an hash with key #{key}" do
        plage_ouverture = build(:plage_ouverture)
        expect(plage_ouverture.payload).to have_key(key)
      end
    end

    describe ":action" do
      it "return an hash with key action key and value" do
        plage_ouverture = build(:plage_ouverture)
        expect(plage_ouverture.payload(:create)[:action]).to eq(:create)
      end
    end

    describe ":name" do
      let(:plage_ouverture) { build(:plage_ouverture, title: "something", start_time: Time.zone.parse("12h30"), first_day: Date.new(2020, 11, 13)) }

      it { expect(plage_ouverture.payload[:name]).to eq("plage-ouverture-something-2020-11-13-12-30-00-0100.ics") }
    end

    describe ":starts_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, start_time: starts_at, first_day: starts_at.to_date) }

      it { expect(plage_ouverture.payload[:starts_at]).to eq(starts_at) }
    end

    describe ":recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_h) }

      it "works" do
        expect(plage_ouverture.payload[:recurrence]).to eq("FREQ=WEEKLY;BYDAY=WE;")
      end
    end

    describe ":ical_uid" do
      let(:plage_ouverture) { create(:plage_ouverture) }

      it { expect(plage_ouverture.payload[:ical_uid]).to eq("plage_ouverture_#{plage_ouverture.id}@RDV Solidarités") }
    end

    describe ":ends_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, end_time: starts_at + 5.hours, first_day: starts_at.to_date) }

      it { expect(plage_ouverture.payload[:ends_at]).to eq(starts_at + 5.hours) }
    end
  end
end
