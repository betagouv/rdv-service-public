describe Admin::Ics::PlageOuverture, type: :service do
  describe "#payload" do
    [:name, :object, :agent_email, :starts_at, :recurrence, :ical_uid, :title, :first_occurence_ends_at, :address].each do |key|
      it "return an hash with key #{key}" do
        plage_ouverture = build(:plage_ouverture)
        expect(described_class.payload(plage_ouverture)).to have_key(key)
      end
    end

    describe ":name" do
      let(:plage_ouverture) { build(:plage_ouverture, title: "something", start_time: Time.zone.parse("12h30"), first_day: Date.new(2020, 11, 13)) }
      it { expect(described_class.payload(plage_ouverture)[:name]).to eq("plage-ouverture-something-2020-11-13-12-30-00-0100.ics") }
    end

    describe ":object" do
      let(:plage_ouverture) { build(:plage_ouverture) }
      it { expect(described_class.payload(plage_ouverture)[:object]).to eq("plage_ouverture") }
    end

    describe ":agent_email" do
      let(:plage_ouverture) { build(:plage_ouverture, agent: build(:agent, email: "polo@demo.rdv-solidarites.fr")) }
      it { expect(described_class.payload(plage_ouverture)[:agent_email]).to eq("polo@demo.rdv-solidarites.fr") }
    end

    describe ":starts_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, start_time: starts_at, first_day: starts_at.to_date) }
      it { expect(described_class.payload(plage_ouverture)[:starts_at]).to eq(starts_at) }
    end

    describe ":recurrence" do
      let(:plage_ouverture) { build(:plage_ouverture, recurrence: Montrose.every(:week, starts: Date.new(2020, 11, 18), on: [:wednesday]).to_json) }
      it { expect(described_class.payload(plage_ouverture)[:recurrence]).to eq("FREQ=WEEKLY;BYDAY=WE;") }
    end

    describe ":ical_uid" do
      let(:plage_ouverture) { create(:plage_ouverture) }
      it { expect(described_class.payload(plage_ouverture)[:ical_uid]).to eq("plage_ouverture_#{plage_ouverture.id}@#{BRAND}") }
    end

    describe ":title" do
      let(:plage_ouverture) { build(:plage_ouverture, title: "Permanence") }
      it { expect(described_class.payload(plage_ouverture)[:title]).to eq("Permanence") }
    end

    describe ":first_occurence_ends_at" do
      let(:starts_at) { Time.zone.parse("20201009 11h45") }
      let(:plage_ouverture) { build(:plage_ouverture, end_time: starts_at + 5.hours, first_day: starts_at.to_date) }
      it { expect(described_class.payload(plage_ouverture)[:first_occurence_ends_at]).to eq(starts_at + 5.hours) }
    end

    describe ":address" do
      let(:lieu) { build(:lieu, address: "10 rue de là-bas") }
      let(:plage_ouverture) { build(:plage_ouverture, lieu: lieu) }
      it { expect(described_class.payload(plage_ouverture)[:address]).to eq("10 rue de là-bas") }
    end
  end

  [:create, :update, :destroy].each do |action|
    describe "##{action}_payload_for" do
      it "return an hash with key action key and value #{action}" do
        expect(described_class.send("#{action}_payload", build(:plage_ouverture))[:action]).to eq(action)
      end
    end
  end

  describe "#to_ical" do
    let(:now) { Time.zone.parse("20190628 17h43") }
    let(:first_day) { Date.new(2019, 7, 22) }
    before { travel_to(now) }
    after { travel_back }

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

    subject { described_class.to_ical(payload) }

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
      is_expected.to include("END:VEVENT")
    end

    context "with a create action" do
      let(:create_payload) { payload.merge(action: :create) }
      subject { described_class.to_ical(create_payload) }
      it { is_expected.to include("STATUS:CONFIRMED") }
    end

    context "with an update action" do
      let(:update_payload) { payload.merge(action: :update) }
      subject { described_class.to_ical(update_payload) }
      it { is_expected.to include("STATUS:CONFIRMED") }
    end

    context "with a destroy action" do
      let(:destroy_payload) { payload.merge(action: :destroy) }
      subject { described_class.to_ical(destroy_payload) }
      it { is_expected.to include("STATUS:CANCELLED") }
    end

    context "with recurrence" do
      let(:recurrence_payload) { payload.merge(recurrence: "FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10") }
      subject { described_class.to_ical(payload) }
      it { is_expected.to include("RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10") }
    end
  end

  describe "#rrule" do
    let(:now) { Time.zone.parse("20190628 17h43") }
    let(:first_day) { Date.new(2019, 7, 22) }
    before { travel_to(now) }
    after { travel_back }

    let(:plage_ouverture) { build(:plage_ouverture, recurrence: recurrence) }

    subject { described_class.rrule(plage_ouverture) }

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
