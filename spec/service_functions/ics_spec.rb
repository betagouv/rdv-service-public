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
    context "_plage_ouverture" do
      let(:payload) do
        {
          name: "plage-ouverture--.ics",
          object: "plage_ouverture",
          event: "created",
          agent_email: "bob@demo.rdv-solidarites.fr",
          starts_at: Time.zone.parse("20190704 15h00"),
          recurrence: "",
          ical_uid: "XE1324",
          title: "Elisa SIMON <> Consultation initiale",
          first_occurence_ends_at: Time.zone.parse("20190704 15h45"),
          address: "10 rue de la Ferronerie 44100 Nantes"
        }
      end

      subject { Ics.to_ical(payload) }

      it do
        is_expected.to include("SUMMARY:RDV Solidarités Elisa SIMON <> Consultation initiale")
        is_expected.to match("DTSTART;TZID=Europe/Paris:20190704T150000")
        is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500")
        is_expected.to include("UID:")
        is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        is_expected.to include("ATTENDEE:mailto:bob@demo.rdv-solidarites.fr")
        is_expected.to include("METHOD:REQUEST")
      end

      context "when the motif is by_phone" do
        # TODO: this does not test for RDVs by phone at all.
        it { is_expected.to include("LOCATION:") }
      end
    end
  end
end
