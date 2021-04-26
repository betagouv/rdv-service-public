describe Admin::Ics::Absence, type: :service do
  describe "#payload" do
    %i[name agent_email starts_at recurrence ical_uid title first_occurrence_ends_at].each do |key|
      it "return an hash with key #{key}" do
        absence = build(:absence)
        expect(described_class.payload(absence)).to have_key(key)
      end
    end

    describe ":name" do
      let(:absence) { build(:absence, title: "something", start_time: Time.zone.parse("12h30"), first_day: Date.new(2020, 11, 13)) }

      it { expect(described_class.payload(absence)[:name]).to eq("plage-ouverture-something-2020-11-13-12-30-00-0100.ics") }
    end

    describe ":agent_email" do
      let(:absence) { build(:absence, agent: build(:agent, email: "polo@demo.rdv-solidarites.fr")) }

      it { expect(described_class.payload(absence)[:agent_email]).to eq("polo@demo.rdv-solidarites.fr") }
    end

    describe ":starts_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:absence) { build(:absence, start_time: starts_at, first_day: starts_at.to_date) }

      it { expect(described_class.payload(absence)[:starts_at]).to eq(starts_at) }
    end

    describe ":recurrence" do
      let(:absence) { build(:absence, recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_json) }

      it { expect(described_class.payload(absence)[:recurrence]).to eq("FREQ=WEEKLY;BYDAY=WE;") }
    end

    describe ":ical_uid" do
      let(:absence) { create(:absence) }

      it { expect(described_class.payload(absence)[:ical_uid]).to eq("absence_#{absence.id}@#{BRAND}") }
    end

    describe ":title" do
      let(:absence) { build(:absence, title: "Permanence") }

      it { expect(described_class.payload(absence)[:title]).to eq("Permanence") }
    end

    describe ":first_occurrence_ends_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:absence) { build(:absence, end_time: starts_at + 5.hours, first_day: starts_at.to_date) }

      it { expect(described_class.payload(absence)[:first_occurrence_ends_at]).to eq(starts_at + 5.hours) }
    end
  end

  %i[create update destroy].each do |action|
    describe "##{action}_payload_for" do
      it "return an hash with key action key and value #{action}" do
        expect(described_class.send("#{action}_payload", build(:absence))[:action]).to eq(action)
      end
    end
  end

  describe "#to_ical" do
    subject { described_class.to_ical(payload) }

    let(:now) { Time.zone.parse("20190628 17h43") }
    let(:payload) do
      {
        name: "plage-ouverture--.ics",
        agent_email: "bob@demo.rdv-solidarites.fr",
        starts_at: Time.zone.parse("20190704 15h00"),
        recurrence: "",
        ical_uid: "absence_15@RDV Solidarités",
        title: "Elisa SIMON <> Consultation initiale",
        first_occurrence_ends_at: Time.zone.parse("20190704 15h45"),
        address: "10 rue de la Ferronerie 44100 Nantes"
      }
    end
    let(:first_day) { Date.new(2019, 7, 22) }

    before { travel_to(now) }

    after { travel_back }

    it do
      expect(subject).to include("METHOD:REQUEST")
      expect(subject).to include("BEGIN:VEVENT")
      expect(subject).to include("DTSTAMP:20190628T154300Z")
      expect(subject).to include("DTSTART;TZID=Europe/Paris:20190704T150000")
      expect(subject).to include("DTEND;TZID=Europe/Paris:20190704T154500")
      expect(subject).to include("CLASS:PUBLIC")
      expect(subject).to include("UID:absence_15@RDV Solidarités")
      expect(subject).to include("SUMMARY:RDV Solidarités Elisa SIMON <> Consultation initiale")
      expect(subject).to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
      expect(subject).to include("END:VEVENT")
    end

    context "with a create action" do
      subject { described_class.to_ical(create_payload) }

      let(:create_payload) { payload.merge(action: :create) }

      it { is_expected.to include("STATUS:CONFIRMED") }
    end

    context "with an update action" do
      subject { described_class.to_ical(update_payload) }

      let(:update_payload) { payload.merge(action: :update) }

      it { is_expected.to include("STATUS:CONFIRMED") }
    end

    context "with a destroy action" do
      subject { described_class.to_ical(destroy_payload) }

      let(:destroy_payload) { payload.merge(action: :destroy) }

      it { is_expected.to include("STATUS:CANCELLED") }
    end

    context "with recurrence" do
      subject { described_class.to_ical(recurrence_payload) }

      let(:recurrence_payload) { payload.merge(recurrence: "FREQ=WEEKLY;") }

      it { is_expected.to include("FREQ=WEEKLY") }
    end
  end

  describe "#rrule" do
    subject { described_class.rrule(absence) }

    let(:now) { Time.zone.parse("20190628 17h43") }
    let(:absence) { build(:absence, recurrence: recurrence) }
    let(:first_day) { Date.new(2019, 7, 22) }

    before { travel_to(now) }

    after { travel_back }

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
