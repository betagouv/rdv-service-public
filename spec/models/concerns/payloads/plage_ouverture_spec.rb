# frozen_string_literal: true

describe Payloads::PlageOuverture do
  describe "#payload" do
    %i[name agent_email starts_at recurrence ical_uid title ends_at address].each do |key|
      it "return an hash with key #{key}" do
        plage_ouverture = build(:plage_ouverture)
        expect(plage_ouverture.payload).to have_key(key)
      end
    end

    describe ":action" do
      it "return an hash with key action key and value " do
        plage_ouverture = build(:plage_ouverture)
        expect(plage_ouverture.payload(:create)[:action]).to eq(:create)
      end
    end

    describe ":name" do
      let(:plage_ouverture) { build(:plage_ouverture, title: "something", start_time: Time.zone.parse("12h30"), first_day: Date.new(2020, 11, 13)) }

      it { expect(plage_ouverture.payload[:name]).to eq("plage-ouverture-something-2020-11-13-12-30-00-0100.ics") }
    end

    describe ":agent_email" do
      let(:plage_ouverture) { build(:plage_ouverture, agent: build(:agent, email: "polo@demo.rdv-solidarites.fr")) }

      it { expect(plage_ouverture.payload[:agent_email]).to eq("polo@demo.rdv-solidarites.fr") }
    end

    describe ":starts_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, start_time: starts_at, first_day: starts_at.to_date) }

      it { expect(plage_ouverture.payload[:starts_at]).to eq(starts_at) }
    end

    describe ":recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_json) }

      it { expect(plage_ouverture.payload[:recurrence]).to eq("FREQ=WEEKLY;BYDAY=WE;") }
    end

    describe ":ical_uid" do
      let(:plage_ouverture) { create(:plage_ouverture) }

      it { expect(plage_ouverture.payload[:ical_uid]).to eq("plage_ouverture_#{plage_ouverture.id}@#{BRAND}") }
    end

    describe ":title" do
      let(:plage_ouverture) { build(:plage_ouverture, title: "Permanence") }

      it { expect(plage_ouverture.payload[:title]).to eq("Permanence") }
    end

    describe ":ends_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, end_time: starts_at + 5.hours, first_day: starts_at.to_date) }

      it { expect(plage_ouverture.payload[:ends_at]).to eq(starts_at + 5.hours) }
    end

    describe ":address" do
      let(:lieu) { build(:lieu, address: "10 rue de là-bas") }
      let(:plage_ouverture) { build(:plage_ouverture, lieu: lieu) }

      it { expect(plage_ouverture.payload[:address]).to eq("10 rue de là-bas") }
    end
  end
end
