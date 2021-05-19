# frozen_string_literal: true

describe Admin::Ics::Rdv, type: :service do
  describe "#payload" do
    %i[name ical_uid summary ends_at sequence description address user_email].each do |key|
      it "return an hash with key #{key}" do
        user = build(:user)
        rdv = build(:rdv, users: [user])
        expect(described_class.payload(rdv, user)).to have_key(key)
      end
    end

    describe ":name" do
      let(:user) { build(:user) }
      let(:rdv) { build(:rdv, users: [user], starts_at: Time.zone.parse("20201123 15h50")) }

      it { expect(described_class.payload(rdv, user)[:name]).to eq("rdv-#{rdv.uuid}-2020-11-23-15-50-00-0100.ics") }
    end

    describe ":starts_at" do
      let(:user) { build(:user) }
      let(:starts_at) { Time.zone.parse("20201123 15h50") }
      let(:rdv) { build(:rdv, users: [user], starts_at: starts_at) }

      it { expect(described_class.payload(rdv, user)[:starts_at]).to eq(starts_at) }
    end

    describe ":ends_at" do
      let(:user) { build(:user) }
      let(:starts_at) { Time.zone.parse("20201123 15h50") }
      let(:rdv) { build(:rdv, users: [user], starts_at: Time.zone.parse("20201123 15h50"), duration_in_min: 10) }

      it { expect(described_class.payload(rdv, user)[:ends_at]).to eq(starts_at + 10.minutes) }
    end

    describe ":sequence" do
      let(:user) { build(:user) }
      let(:rdv) { build(:rdv, users: [user], sequence: 1) }

      it { expect(described_class.payload(rdv, user)[:sequence]).to eq(1) }
    end

    describe ":description" do
      let(:user) { build(:user) }
      let(:rdv) { build(:rdv, users: [user]) }

      it { expect(described_class.payload(rdv, user)[:description]).to eq("Infos et annulation: #{ENV['HOST']}/r") }
    end

    describe ":address" do
      let(:user) { build(:user) }

      context "with a phone motif" do
        let(:rdv) { build(:rdv, users: [user], motif: build(:motif, :by_phone)) }

        it { expect(described_class.payload(rdv, user)[:address]).to be_nil }
      end

      context "without a phone motif" do
        let(:rdv) { build(:rdv, users: [user], motif: build(:motif, :public_office), lieu: build(:lieu, address: "17 rue de l'adresse")) }

        it { expect(described_class.payload(rdv, user)[:address]).to eq("17 rue de l'adresse") }
      end
    end

    describe ":ical_uid" do
      let(:user) { create(:user) }
      let(:rdv) { create(:rdv, users: [user]) }

      it { expect(described_class.payload(rdv, user)[:ical_uid]).to eq(rdv.uuid) }
    end

    describe ":summary" do
      let(:user) { build(:user, first_name: "Ethan", last_name: "DUVAL") }
      let(:rdv) { build(:rdv, users: [user], motif: build(:motif, name: "Consultation")) }

      it { expect(described_class.payload(rdv, user)[:summary]).to eq("RDV Ethan DUVAL <> Consultation") }
    end

    describe ":user_email" do
      let(:user) { build(:user, email: "bob@eponge.net") }
      let(:rdv) { build(:rdv, users: [user]) }

      it { expect(described_class.payload(rdv, user)[:user_email]).to eq("bob@eponge.net") }
    end
  end

  describe "#to_ical" do
    let(:now) { Time.zone.parse("20190628 17h43") }
    let(:first_day) { Date.new(2019, 7, 22) }

    before { travel_to(now) }

    after { travel_back }

    context "_rdv" do
      subject { described_class.to_ical(payload) }

      let(:payload) do
        {
          name: "rdv--.ics",
          summary: "RDV Elisa SIMON <> Consultation initiale",
          starts_at: Time.zone.parse("20190704 15h00"),
          ends_at: Time.zone.parse("20190704 15h45"),
          sequence: 0,
          description: "Infos et annulation:",
          address: "10 rue de la Ferronerie 44100 Nantes",
          user_email: "elisa@simon.fr",
          ical_uid: "rdv_15@RDV Solidarités"
        }
      end

      it do
        expect(subject).to include("METHOD:REQUEST")
        expect(subject).to include("BEGIN:VEVENT")
        expect(subject).to include("SUMMARY:RDV Elisa SIMON <> Consultation initiale")
        expect(subject).to include("DTSTART;TZID=Europe/Paris:20190704T150000")
        expect(subject).to include("DTEND;TZID=Europe/Paris:20190704T154500")
        expect(subject).to include("SEQUENCE:0")
        expect(subject).to include("UID:rdv_15@RDV Solidarités")
        expect(subject).to include("DESCRIPTION:Infos et annulation:")
        expect(subject).to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        expect(subject).to include("ATTENDEE:mailto:elisa@simon.fr")
        expect(subject).to include("CLASS:PRIVATE")
        expect(subject).to include("DTSTAMP:20190628T154300Z")
        expect(subject).to include("END:VEVENT")
      end
    end
  end
end
