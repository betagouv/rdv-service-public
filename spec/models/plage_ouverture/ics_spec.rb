describe PlageOuverture::Ics, type: :model do
  describe '#to_ical' do
    let(:plage_ouverture) { create(:plage_ouverture) }
    let(:ics) { PlageOuverture::Ics.new(plage_ouverture: plage_ouverture) }
    subject { ics.to_ical }

    it do
      is_expected.to include("SUMMARY:RDV Solidarités #{plage_ouverture.title}")
      is_expected.to match("DTSTART;TZID=Europe/Paris:20190722T080000")
      is_expected.to include("DTEND;TZID=Europe/Paris:20190722T120000")
      is_expected.to include("LOCATION:1 rue de l'adresse\\, 12345 Ville")
      is_expected.to include("ORGANIZER:noreply@rdv-solidarites.fr")
      is_expected.to include("ATTENDEE:#{plage_ouverture.agent.email}")
      is_expected.to include("CLASS:PRIVATE")
      is_expected.to include("METHOD:REQUEST")
    end
  end
end
