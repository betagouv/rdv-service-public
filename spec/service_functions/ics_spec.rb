describe Ics, type: :service do
  let(:now) { Time.zone.parse("20190628 17h43") }
  let(:first_day) { Date.new(2019, 7, 22) }

  before { travel_to(now) }
  after { travel_back }

  describe "#payload_for" do
    [:name, :object, :agent_email, :starts_at, :recurrence, :ical_uid, :title, :first_occurence_ends_at, :address].each do |key|
      it "return an hash with key #{key}" do
        plage_ouverture = build(:plage_ouverture)
        expect(Ics.payload_for(plage_ouverture)).to have_key(key)
      end
    end
  end

  [:create, :update, :destroy].each do |event|
    describe "##{event}_payload_for" do
      it "return an hash with key event key and value #{event}" do
        expect(Ics.send("#{event}_payload_for", build(:plage_ouverture))[:event]).to eq(event)
      end
    end
  end

  describe "#to_ical_for" do
    context "_plage_ouverture" do
      let(:payload) do
        {
          name: "plage-ouverture--.ics",
          object: "plage_ouverture",
          agent_email: "bob@demo.rdv-solidarites.fr",
          starts_at: Time.zone.parse("20190704 15h00"),
          recurrence: "",
          ical_uid: "plage_ouverture_15@RDV Solidarités",
          title: "Elisa SIMON <> Consultation initiale",
          first_occurence_ends_at: Time.zone.parse("20190704 15h45"),
          address: "10 rue de la Ferronerie 44100 Nantes"
        }
      end

      subject { Ics.to_ical(payload) }

      it do
        is_expected.to include("METHOD:REQUEST")
        is_expected.to include("BEGIN:VEVENT")
        is_expected.to include("DTSTAMP:20190628T154300Z")
        is_expected.to include("DTSTART;TZID=Europe/Paris:20190704T150000")
        is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500")
        is_expected.to include("CLASS:PUBLIC")
        is_expected.to include("UID:plage_ouverture_15@RDV Solidarités")
        is_expected.to include("SUMMARY:RDV Solidarités Elisa SIMON <> Consultation initiale")
        is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        is_expected.to include("ORGANIZER:bob@demo.rdv-solidarites.fr")
        is_expected.to include("END:VEVENT")
      end
    end

    context "_plage_ouverture create" do
      let(:payload) do
        {
          name: "plage-ouverture--.ics",
          object: "plage_ouverture",
          event: :create,
          agent_email: "bob@demo.rdv-solidarites.fr",
          starts_at: Time.zone.parse("20190704 16h00"),
          recurrence: "",
          ical_uid: "plage_ouverture_15@RDV Solidarités",
          title: "Elisa SIMON <> Consultation initiale",
          first_occurence_ends_at: Time.zone.parse("20190704 16h45"),
          address: "10 rue de la Ferronerie 44100 Nantes"
        }
      end

      subject { Ics.to_ical(payload) }

      it do
        is_expected.to include("ATTENDEE;CN=bob@demo.rdv-solidarites.fr:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("STATUS:CONFIRMED")
      end
    end

    context "_plage_ouverture update" do
      let(:payload) do
        {
          name: "plage-ouverture--.ics",
          object: "plage_ouverture",
          event: :update,
          agent_email: "bob@demo.rdv-solidarites.fr",
          starts_at: Time.zone.parse("20190704 16h00"),
          recurrence: "",
          ical_uid: "plage_ouverture_15@RDV Solidarités",
          title: "Elisa SIMON <> Consultation initiale",
          first_occurence_ends_at: Time.zone.parse("20190704 16h45"),
          address: "10 rue de la Ferronerie 44100 Nantes"
        }
      end

      subject { Ics.to_ical(payload) }

      it do
        is_expected.to include("ATTENDEE;CN=bob@demo.rdv-solidarites.fr:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("STATUS:CONFIRMED")
      end
    end

    context "_plage_ouverture destroy" do
      let(:payload) do
        {
          name: "plage-ouverture--.ics",
          object: "plage_ouverture",
          event: :destroy,
          agent_email: "bob@demo.rdv-solidarites.fr",
          starts_at: Time.zone.parse("20190704 16h00"),
          recurrence: "",
          ical_uid: "plage_ouverture_15@RDV Solidarités",
          title: "Elisa SIMON <> Consultation initiale",
          first_occurence_ends_at: Time.zone.parse("20190704 16h45"),
          address: "10 rue de la Ferronerie 44100 Nantes"
        }
      end

      subject { Ics.to_ical(payload) }

      it do
        is_expected.to include("ATTENDEE;CN=bob@demo.rdv-solidarites.fr:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("STATUS:CANCELLED")
      end
    end
  end

  describe "#rrule" do
    let(:payload) { { recurrence: recurrence } }

    subject { Ics.rrule(payload) }

    context "every week" do
      let(:recurrence) { Montrose.every(:week, on: ["monday"], starts: first_day) }

      it { is_expected.to eq("FREQ=WEEKLY;BYDAY=MO;") }

      context "on monday and wednesday" do
        let(:recurrence) { Montrose.every(:week, on: %w[monday tuesday wednesday thursday friday saturday], starts: first_day) }

        it { is_expected.to eq("FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;") }
      end

      context "until 22/10/2019" do
        let(:recurrence) { Montrose.every(:week, until: Time.zone.local(2019, 10, 22), starts: first_day) }

        it { is_expected.to eq("FREQ=WEEKLY;UNTIL=20191022T000000;") }
      end
    end

    context "every 2 weeks" do
      let(:recurrence) { Montrose.every(:week, interval: 2, starts: first_day) }

      it { is_expected.to eq("FREQ=WEEKLY;INTERVAL=2;") }
    end

    context "every month" do
      let(:recurrence) { Montrose.every(:month, starts: first_day) }

      it { is_expected.to eq("FREQ=MONTHLY;") }

      context "the 2nd wednesday of the month" do
        let(:recurrence) { Montrose.every(:month, day: { 3 => [2] }, starts: first_day) }

        it { is_expected.to eq("FREQ=MONTHLY;BYDAY=2WE;") }
      end
    end
  end
end
