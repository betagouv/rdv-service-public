describe TwilioTextMessenger, type: :service, skip_mock_sms: true do
  let(:user) { create(:user, phone_number: "+33640404040") }

  describe "#send_sms" do
    let(:service_pmi) { create(:service, :pmi) }
    let(:motif) { create(:motif, service: service_pmi) }
    let(:motif_by_phone) { create(:motif, :by_phone, service: service_pmi) }
    let(:twilio_client) { instance_double(Twilio::REST::Client) }
    let(:twilio_messages_list) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }

    before do
      expect(Twilio::REST::Client).to receive(:new).at_least(:once).and_return(twilio_client)
      expect(twilio_client).to receive(:messages).at_least(:once).and_return(twilio_messages_list)
    end

    context "for rdv_created notifications" do
      context "simple RDV" do
        let(:rdv) do
          create_rdv(
            motif: motif,
            users: [user],
            location: "20 rue du Louvre, Paris",
            starts_at: Time.zone.parse("2020-10-25 10:30")
          )
        end
        it 'should call twilio message creation' do
          expect(twilio_messages_list).to receive(:create).with(
            from: ENV["TWILIO_PHONE_NUMBER"],
            to: "+33640404040",
            body: "RDV PMI 25 oct. à 10h30\n20 rue du Louvre, Paris\nInfos et annulation: #{ENV['HOST']}/r"
          )
          TwilioTextMessenger.new(:rdv_created, rdv, user).send_sms
        end
      end

      context 'phone RDV' do
        let(:rdv) do
          create_rdv(
            motif: motif_by_phone,
            users: [user],
            starts_at: Time.zone.parse("2020-10-25 10:30")
          )
        end
        it "should call twilio message creation" do
          expect(twilio_messages_list).to receive(:create).with(
            from: ENV["TWILIO_PHONE_NUMBER"],
            to: "+33640404040",
            body: "RDV PMI 25 oct. à 10h30\nRDV Téléphonique\nInfos et annulation: #{ENV['HOST']}/r"
          )
          TwilioTextMessenger.new(:rdv_created, rdv, user).send_sms
        end
      end
    end

    context "when sending a reminder sms" do
      let(:rdv) do
        create_rdv(
          location: "20 rue du Louvre, Paris",
          motif: motif,
          users: [user],
          starts_at: Time.zone.parse("2020-10-25 10:30")
        )
      end
      it "should call twilio message creation" do
        expect(twilio_messages_list).to receive(:create).with(
          from: ENV["TWILIO_PHONE_NUMBER"],
          to: "+33640404040",
          body: "Rappel RDV PMI le 25 oct. à 10h30\n20 rue du Louvre, Paris\nInfos et annulation: #{ENV['HOST']}/r"
        )
        TwilioTextMessenger.new(:reminder, rdv, user).send_sms
      end
    end

    context "when sending a file d'attente sms" do
      let(:rdv) { create_rdv(users: [user]) }
      it "should call twilio message creation" do
        expect(twilio_messages_list).to receive(:create).with(
          from: ENV["TWILIO_PHONE_NUMBER"],
          to: "+33640404040",
          body: "Des créneaux se sont libérés plus tot.\nCliquez pour voir les disponibilités : #{ENV['HOST']}/users/creneaux?rdv_id=#{rdv.id}"
        )
        TwilioTextMessenger.new(:file_attente, rdv, user, creneau_starts_at: Time.now).send_sms
      end
    end

    context "when sending a rdv_cancelled_by_agent sms" do
      let(:rdv) do
        create_rdv(
          motif: motif,
          users: [user],
          starts_at: Time.zone.parse("2020-10-25 10:30")
        )
      end
      it "should call twilio message creation" do
        expect(twilio_messages_list).to receive(:create).with(
          from: ENV["TWILIO_PHONE_NUMBER"],
          to: "+33640404040",
          body: "RDV PMI 25 oct. à 10h30 a été annulé\nAllez sur https://rdv-solidarites.fr pour reprendre RDV."
        )
        TwilioTextMessenger.new(:rdv_cancelled, rdv, user).send_sms
      end
    end
  end

  describe "#replace_special_chars" do
    it "should work" do
      body = "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ"
      expect(
        TwilioTextMessenger
          .new(:rdv_created, nil, user)
          .send(:replace_special_chars, body)
      ).to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ")
    end
  end
end

def create_rdv(*args, **kwargs)
  rdv = build(:rdv, *args, **kwargs)
  rdv.extend(SkipCallbacks)
  rdv.save!
  rdv
end
