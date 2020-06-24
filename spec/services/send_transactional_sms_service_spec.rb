describe SendTransactionalSmsService, type: :service do
  let(:user) { create(:user, phone_number: "+33640404040", address: "10 rue de Toulon, Lille") }

  describe ".sms_footer" do
    let(:rdv) { create(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now) }
    subject { SendTransactionalSmsService.new(:rdv_created, rdv, user).send(:sms_footer) }

    context "when regular Rdv" do
      let(:motif) { create(:motif, :at_public_office) }
      it { should include(rdv.address) }
    end

    context "when Rdv is at home" do
      let(:motif) { create(:motif, :at_home) }
      it { should include("RDV à domicile") }
      it { should include(rdv.address) }
    end

    context "when Rdv is by phone" do
      let(:motif) { create(:motif, :by_phone) }
      it { should include("RDV Téléphonique") }
      it { should include(rdv.address) }
    end
  end

  describe ".send(type)" do
    let(:rdv) { create(:rdv, users: [user], starts_at: 5.days.from_now) }

    subject { SendTransactionalSmsService.new(:rdv_created, rdv, user).send(type) }

    context "when rdv created" do
      let(:type) { :rdv_created }
      it { should include("RDV #{rdv.motif.service.short_name} #{I18n.l(rdv.starts_at, format: :short)}") }
    end

    context "when rdv reminder" do
      let(:type) { :reminder }

      it { should include("Rappel RDV #{rdv.motif.service.short_name} le #{I18n.l(rdv.starts_at, format: :short)}") }
    end

    context "when rdv is cancelled" do
      let(:type) { :rdv_cancelled }

      it { should include("RDV #{rdv.motif.service.short_name} #{I18n.l(rdv.starts_at, format: :short)} a été annulé") }
    end

    context "when is for file_attente" do
      let(:type) { :file_attente }
    end
  end

  describe "#replace_special_chars" do
    it "should work" do
      body = "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ"
      expect(
        SendTransactionalSmsService
          .new(:rdv_created, nil, user)
          .send(:replace_special_chars, body)
      ).to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ")
    end
  end
end
