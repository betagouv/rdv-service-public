module SomeModule
  class TestSms
    include TransactionalSms::BaseConcern

    def raw_content
      "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ"
    end
  end
end

describe TransactionalSms::BaseConcern, type: :service do
  let(:user) { build(:user, phone_number: "+33640404040", address: "10 rue de Toulon, Lille") }

  describe "#rdv_footer" do
    let(:rdv) { build(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now) }
    subject { SomeModule::TestSms.new(rdv, user).rdv_footer }

    context "when regular Rdv" do
      let(:motif) { build(:motif, :at_public_office) }
      it { should include(rdv.address) }
    end

    context "when Rdv is at home" do
      let(:motif) { build(:motif, :at_home) }
      it { should include("RDV à domicile") }
      it { should include(rdv.address) }
    end

    context "when Rdv is by phone" do
      let(:motif) { build(:motif, :by_phone) }
      it { should include("RDV Téléphonique") }
      it { should include(rdv.address) }
    end
  end

  describe "#tags" do
    let(:organisation) { create(:organisation, departement: "77") }
    let(:rdv) { build(:rdv, organisation: organisation) }
    subject { SomeModule::TestSms.new(rdv, build(:user)).tags }
    it { should include("org-#{organisation.id}") }
    it { should include("dpt-77") }
    it { should include("test_sms") }
  end

  describe "#content" do
    subject { SomeModule::TestSms.new(build(:rdv), build(:user)).content }
    it { should eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ") }
  end

  describe "#send!" do
    let(:sms) { SomeModule::TestSms.new(build(:rdv), build(:user)) }
    before do
      expect(SendTransactionalSmsService).to receive(:perform_with).with(sms)
    end
    it "should call send service" do
      sms.send!
    end
  end
end
