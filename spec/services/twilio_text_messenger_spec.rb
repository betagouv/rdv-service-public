describe TwilioTextMessenger, type: :service do
  let(:rdv) { create(:rdv) }
  let(:user) { rdv.users.first }

  describe "#send_sms" do
    subject { twilio.send_sms }

    context "when sending a sms when rdv is created" do
      let(:twilio) { TwilioTextMessenger.new(:rdv_created, rdv, user) }
      it 'return Twilio Object when sms is sent' do
        is_expected.to be_kind_of(Twilio::REST::Api::V2010::AccountContext::MessageInstance)
      end

      it { expect(subject.body).to include("RDV #{rdv.motif.service.name} #{I18n.l(rdv.starts_at, format: :short)}") }
      it { expect(subject.body).to include(rdv.location.to_s) }

      context 'RDV is by_phone' do
        let(:rdv) { create(:rdv, :by_phone) }

        it { expect(subject.body).to include("RDV Téléphonique") }
      end
    end

    context "when sending a reminder sms" do
      let(:twilio) { TwilioTextMessenger.new(:reminder, rdv, user) }
      it 'return Twilio Object when sms is sent' do
        is_expected.to be_kind_of(Twilio::REST::Api::V2010::AccountContext::MessageInstance)
      end

      it { expect(subject.body).to include("Rappel RDV #{rdv.motif.service.name} le #{I18n.localize(rdv.starts_at, format: :short)}") }
      it { expect(subject.body).to include(rdv.location.to_s) }
    end

    context "when sending a file d'attente sms" do
      let(:twilio) { TwilioTextMessenger.new(:file_attente, rdv, user, creneau_starts_at: Time.now) }
      it 'return Twilio Object when sms is sent' do
        is_expected.to be_kind_of(Twilio::REST::Api::V2010::AccountContext::MessageInstance)
      end

      it { expect(subject.body).to include("Des créneaux se sont libérés plus tot.") }
      it { expect(subject.body).to include("Cliquez pour voir les disponibilités :") }
    end
  end

  describe "#replace_special_chars" do
    let(:twilio) { TwilioTextMessenger.new(:rdv_created, rdv, user) }
    let(:body) { "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ" }

    subject { twilio.send(:replace_special_chars, body) }

    it { is_expected.to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ") }
  end
end
