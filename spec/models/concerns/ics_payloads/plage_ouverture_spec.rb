RSpec.describe IcsPayloads::PlageOuverture do
  describe "#payload" do
    %i[name starts_at rrule ical_uid ends_at].each do |key|
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
      let(:plage_ouverture) { build(:plage_ouverture, title: "Permanence mairie", start_time: Tod::TimeOfDay.new(9), first_day: Date.new(2020, 11, 13)) }

      it { expect(plage_ouverture.payload[:name]).to eq("plage-ouverture-permanence-mairie-2020-11-13-09-00-00-0100.ics") }

      context "when title is empty" do
        let(:plage_ouverture) { create(:plage_ouverture, title: nil, start_time: Tod::TimeOfDay.new(9), first_day: Date.new(2020, 11, 13)) }

        it { expect(plage_ouverture.payload[:name]).to eq("plage-ouverture-#{plage_ouverture.id}-2020-11-13-09-00-00-0100.ics") }
      end
    end

    describe ":summary" do
      let(:plage_ouverture) { build(:plage_ouverture, title: "something") }

      it { expect(plage_ouverture.payload[:summary]).to eq("RDV Solidarités something") }

      context "when title is empty" do
        let(:plage_ouverture) { create(:plage_ouverture, title: nil) }

        it { expect(plage_ouverture.payload[:summary]).to eq("RDV Solidarités Plage de 8h-12h") }
      end
    end

    describe ":starts_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, start_time: starts_at, first_day: starts_at.to_date) }

      it { expect(plage_ouverture.payload[:starts_at]).to eq(starts_at) }
    end

    describe ":rrule" do
      let(:plage_ouverture) { build(:plage_ouverture, recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_json) }

      it { expect(plage_ouverture.payload[:rrule]).to eq("FREQ=WEEKLY;BYDAY=WE;") }
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
