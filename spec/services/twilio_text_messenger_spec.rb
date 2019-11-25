describe TwilioTextMessenger, type: :service do
  let(:rdv) { create(:rdv) }
  let(:user) { rdv.users.first }
  let(:twilio) { TwilioTextMessenger.new(rdv, user) }

  subject { twilio.send }

  it 'return Twilio Object when sms is sent' do
    is_expected.to be_kind_of(Twilio::REST::Api::V2010::AccountContext::MessageInstance)
  end

  it { expect(subject.body).to include("RDV Solidarités - Bonjour") }
  it { expect(subject.body).to include("RDV #{rdv.motif.name} #{I18n.l(rdv.starts_at, format: :human)} a été confirmé.") }
  it { expect(subject.body).to include("Adresse: #{rdv.location}.") }

  context 'RDV is by_phone' do
    let(:rdv) { create(:rdv, :by_phone) }

    it { expect(subject.body).to include("RDV Téléphonique") }
  end
end
