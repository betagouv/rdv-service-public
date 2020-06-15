describe Rdv::Ics, type: :model do
  describe '#to_ical_for' do
    let(:motif) { create(:motif, name: "Consultation initiale") }
    let(:user) { create(:user, first_name: "elisa", last_name: "simon", email: "elisa@simon.fr") }
    let(:lieu) { create(:lieu, address: "10 rue de la Ferronerie 44100 Nantes") }
    let(:rdv) { create(:rdv, users: [user], motif: motif, starts_at: Time.zone.local(2019, 7, 4, 15, 0), lieu: lieu) }
    let(:ics) { Rdv::Ics.new(rdv: rdv) }
    subject { ics.to_ical_for(user) }

    it do
      is_expected.to include("SUMMARY:RDV Elisa SIMON <> Consultation initiale")
      is_expected.to match("DTSTART;TZID=Europe/Paris:20190704T150000")
      is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500")
      is_expected.to include("SEQUENCE:0")
      is_expected.to include("UID:")
      is_expected.to include("DESCRIPTION:Infos et annulation:")
      is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
      is_expected.to include("ATTENDEE:mailto:elisa@simon.fr")
      is_expected.to include("CLASS:PRIVATE")
      is_expected.to include("METHOD:REQUEST")
    end

    context 'when the motif is by_phone' do
      # TODO: this does not test for RDVs by phone at all.
      it { is_expected.to include("LOCATION:") }
    end
  end
end
