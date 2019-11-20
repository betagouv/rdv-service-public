describe TwilioTextMessenger, type: :service do
  let(:rdv) { create(:rdv) }
  let(:user) { rdv.users.first }
  let(:twilio) { TwilioTextMessenger.new(rdv, user) }

  subject { twilio.send }

  it 'return Twilio Object when sms is sent' do
    is_expected.to be_kind_of(Twilio::REST::Api::V2010::AccountContext::MessageInstance)
  end

  it 'return Twilio Error when phone is invalid' do
    user.update(phone_number: "0712121212")
    user.reload
    is_expected.to be false
  end
end
