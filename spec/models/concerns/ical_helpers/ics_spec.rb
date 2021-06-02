# frozen_string_literal: true

require "rspec"

describe IcalHelpers::Ics do
  describe "from_payload" do
    subject { described_class.from_payload(payload) }

    let(:payload) do
      {
        name: "rdv--.ics",
        summary: "RDV Elisa SIMON <> Consultation initiale",
        starts_at: Time.zone.parse("20190704 15h00"),
        ends_at: Time.zone.parse("20190704 15h45"),
        sequence: 0,
        description: "Infos et annulation:",
        address: "10 rue de la Ferronerie 44100 Nantes",
        ical_uid: "rdv_15@RDV Solidarités",
        recurrence: "FREQ=WEEKLY;"
      }
    end

    before { travel_to Time.zone.parse("20190628 17h43") } # Needed for DTSTAMP

    describe "fields" do
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
        expect(subject).to include("END:VEVENT")
      end
    end

    describe "status" do
      context "create" do
        let(:payload) { { action: :create } }

        it { expect(subject).to include "STATUS:CONFIRMED" }
      end

      context "update" do
        let(:payload) { { action: :update } }

        it { expect(subject).to include "STATUS:CONFIRMED" }
      end

      context "destroy" do
        let(:payload) { { action: :destroy } }

        it { expect(subject).to include "STATUS:CANCELLED" }
      end
    end
  end
end
