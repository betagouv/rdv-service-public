describe Ics, type: :service do
  describe "#payload_for" do
    [:name, :object, :event, :agent_email, :starts_at, :recurrence, :ical_uid, :title, :first_occurence_ends_at, :address].each do |key|
      it "return an hash with key #{key}" do
        plage_ouverture = build(:plage_ouverture)
        expect(Ics.payload_for(plage_ouverture, :create)).to have_key(key)
      end
    end
  end

  describe "#to_ical_for" do
    context "_plage_ouverture creation" do
      let(:now) { Time.zone.parse("20190628 17h43") }
      before { travel_to(now) }
      after { travel_back }

      let(:payload) do
        {
          name: "plage-ouverture--.ics",
          object: "plage_ouverture",
          event: :created,
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
        is_expected.to include("LAST-MODIFIED:20190628T174300")
        is_expected.to include("DTSTAMP:20190628T154300Z")
        is_expected.to include("DTSTART;TZID=Europe/Paris:20190704T150000")
        is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500")
        is_expected.to include("CLASS:PUBLIC")
        is_expected.to include("UID:plage_ouverture_15@RDV Solidarités")
        is_expected.to include("SUMMARY:RDV Solidarités Elisa SIMON <> Consultation initiale")
        is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        is_expected.to include("ORGANIZER:bob@demo.rdv-solidarites.fr")
        is_expected.to include("ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE")
        is_expected.to include(" ;CN=bob@demo.rdv-solidarites.fr:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("STATUS:CONFIRMED")
        is_expected.to include("END:VEVENT")
      end
    end

    context "_plage_ouverture update" do
      let(:now) { Time.zone.parse("20190628 17h43") }
      before { travel_to(now) }
      after { travel_back }

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
        is_expected.to include("METHOD:REQUEST")
        is_expected.to include("BEGIN:VEVENT")
        is_expected.to include("LAST-MODIFIED:20190628T174300")
        is_expected.to include("UID:plage_ouverture_15@RDV Solidarités")
        is_expected.to include("DTSTAMP:20190628T154300Z")
        is_expected.to include("DTSTART;TZID=Europe/Paris:20190704T160000")
        is_expected.to include("DTEND;TZID=Europe/Paris:20190704T164500")
        is_expected.to include("CLASS:PUBLIC")
        is_expected.to include("SUMMARY:RDV Solidarités Elisa SIMON <> Consultation initiale")
        is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        is_expected.to include("ORGANIZER:bob@demo.rdv-solidarites.fr")
        is_expected.to include("ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE")
        is_expected.to include(" ;CN=bob@demo.rdv-solidarites.fr:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("STATUS:CONFIRMED")
        is_expected.to include("END:VEVENT")
      end
    end

    context "_plage_ouverture destroy" do
      let(:now) { Time.zone.parse("20190628 17h43") }
      before { travel_to(now) }
      after { travel_back }

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
        is_expected.to include("METHOD:REQUEST")
        is_expected.to include("BEGIN:VEVENT")
        is_expected.to include("LAST-MODIFIED:20190628T174300")
        is_expected.to include("DTSTAMP:20190628T154300Z")
        is_expected.to include("UID:plage_ouverture_15@RDV Solidarités")
        is_expected.to include("DTSTART;TZID=Europe/Paris:20190704T160000")
        is_expected.to include("DTEND;TZID=Europe/Paris:20190704T164500")
        is_expected.to include("CLASS:PUBLIC")
        is_expected.to include("SUMMARY:RDV Solidarités Elisa SIMON <> Consultation initiale")
        is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        is_expected.to include("ORGANIZER:bob@demo.rdv-solidarites.fr")
        is_expected.to include("ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE")
        is_expected.to include(" ;CN=bob@demo.rdv-solidarites.fr:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("STATUS:CANCELLED")
        is_expected.to include("END:VEVENT")
      end
    end
  end
end
