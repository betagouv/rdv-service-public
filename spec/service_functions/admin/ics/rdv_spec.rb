describe Admin::Ics::Rdv, type: :service do
  let(:now) { Time.zone.parse("20190628 17h43") }
  let(:first_day) { Date.new(2019, 7, 22) }

  before { travel_to(now) }
  after { travel_back }

  context "with a RDV" do
    describe "#payload_for" do
      [:name, :object, :ical_uid, :summary, :ends_at, :sequence, :description, :address, :user_email].each do |key|
        it "return an hash with key #{key}" do
          user = build(:user)
          rdv = build(:rdv, users: [user])
          expect(described_class.payload(rdv, user)).to have_key(key)
        end
      end
    end

    describe "#create_payload_for" do
      it "return an hash with key action key and value create" do
        user = build(:user)
        rdv = build(:rdv, users: [user])
        expect(described_class.create_payload(rdv, user)[:action]).to eq(:create)
      end
    end

    describe "#payload_for_rdv content"

    describe "#to_ical_for" do
      context "_rdv" do
        let(:payload) do
          {
            name: "rdv--.ics",
            object: "rdv",
            summary: "RDV Elisa SIMON <> Consultation initiale",
            starts_at: Time.zone.parse("20190704 15h00"),
            ends_at: Time.zone.parse("20190704 15h45"),
            sequence: 0,
            description: "Infos et annulation:",
            address: "10 rue de la Ferronerie 44100 Nantes",
            user_email: "elisa@simon.fr",
            ical_uid: "rdv_15@RDV Solidarités",
          }
        end

        subject { described_class.to_ical(payload) }

        it do
          is_expected.to include("METHOD:REQUEST")
          is_expected.to include("BEGIN:VEVENT")
          is_expected.to include("SUMMARY:RDV Elisa SIMON <> Consultation initiale")
          is_expected.to include("DTSTART;TZID=Europe/Paris:20190704T150000")
          is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500")
          is_expected.to include("SEQUENCE:0")
          is_expected.to include("UID:rdv_15@RDV Solidarités")
          is_expected.to include("DESCRIPTION:Infos et annulation:")
          is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
          is_expected.to include("ATTENDEE:mailto:elisa@simon.fr")
          is_expected.to include("CLASS:PRIVATE")
          is_expected.to include("DTSTAMP:20190628T154300Z")
          is_expected.to include("END:VEVENT")
        end
      end
    end
  end
end
