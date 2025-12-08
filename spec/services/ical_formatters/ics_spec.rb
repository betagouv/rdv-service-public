RSpec.describe IcalFormatters::Ics do
  describe "from_payload" do
    subject { described_class.from_payload(payload).to_ical }

    let(:domain) { Domain::RDV_SOLIDARITES }
    let(:payload) do
      {
        name: "rdv--.ics",
        summary: "RDV Elisa SIMON <> Consultation initiale",
        starts_at: Time.zone.parse("20190704 15h00"),
        ends_at: Time.zone.parse("20190704 15h45"),
        sequence: 0,
        description: "Infos et annulation:",
        location: "10 rue de la Ferronerie 44100 Nantes",
        ical_uid: "rdv_15@RDV Solidarités",
        rrule: "FREQ=WEEKLY;",
        domain: domain,
        attendees: ["patricia@gmail.com"],
      }
    end

    before { travel_to Time.zone.parse("20190628 17h43") } # Needed for DTSTAMP

    describe "fields for RDV_SOLIDARITES domain" do
      it do
        expect(subject).to include("BEGIN:VEVENT")
        expect(subject).to include("DTSTART;TZID=Europe/Paris:20190704T150000")
        expect(subject).to include("DTEND;TZID=Europe/Paris:20190704T154500")
        expect(subject).to include("DTSTAMP:20190628T154300Z")
        expect(subject).to include("SEQUENCE:0")
        expect(subject).to include("UID:rdv_15@RDV Solidarités")
        expect(subject).to include("SUMMARY:RDV Elisa SIMON <> Consultation initiale")
        expect(subject).to include("DESCRIPTION:Infos et annulation:")
        expect(subject).to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
        expect(subject).to include("RRULE:FREQ=WEEKLY")
        expect(subject).to include("ORGANIZER:mailto:secretariat-auto@rdv-solidarites.fr")
        expect(subject).to include("END:VEVENT")
        expect(subject).to include("ATTENDEE;PARTSTAT=ACCEPTED:mailto:patricia@gmail.com")
      end
    end

    describe "fields for RDV_SERVICE_PUBLIC domain" do
      let(:domain) { Domain::RDV_SERVICE_PUBLIC }

      it do
        expect(subject).to include("ORGANIZER:mailto:secretariat-auto@rdv-service-public.fr")
      end
    end

    describe "status" do
      let(:payload) { { starts_at: Time.zone.parse("20190704 15h00"), action: action, domain: Domain::RDV_SOLIDARITES } }

      context "create" do
        let(:action) { :create }

        it { expect(subject).to include "STATUS:CONFIRMED" }
      end

      context "update" do
        let(:action) { :update }

        context "when status is not provided" do
          it { expect(subject).to include "STATUS:CONFIRMED" }
        end

        context "when status is provided" do
          let(:payload) { super().merge(status: "CANCELLED") }

          it { expect(subject).to include "STATUS:CANCELLED" }
        end
      end

      context "destroy" do
        let(:action) { :destroy }

        it { expect(subject).to include "STATUS:CANCELLED" }
      end
    end
  end
end
