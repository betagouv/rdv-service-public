describe Rdv::Ics, type: :model do
  describe '#to_ical_for' do
    let(:rdv) { create(:rdv) }
    let(:rdv_by_phone) { create :rdv, :by_phone }
    let(:user) { rdv.users.first }
    let(:ics) { Rdv::Ics.new(rdv: rdv) }
    subject { ics.to_ical_for(user) }

    it do
      is_expected.to include("SUMMARY:RDV #{rdv.name_for_user(user)}")
      is_expected.to match("DTSTART;TZID=Europe/Paris:20190704T150000")
      is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500")
      is_expected.to include("SEQUENCE:0")
      is_expected.to include("UID:")
      is_expected.to include("DESCRIPTION:Infos et annulation:")
      is_expected.to include("LOCATION:10 rue de la Ferronerie 44100 Nantes")
      is_expected.to include("ATTENDEE:mailto:#{user.email}")
      is_expected.to include("CLASS:PRIVATE")
      is_expected.to include("METHOD:REQUEST")
    end

    context 'when the motif is by_phone' do
      it { is_expected.to include("LOCATION:") }
    end
  end
end
