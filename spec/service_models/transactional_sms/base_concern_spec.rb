module SomeModule
  class TestSms
    include TransactionalSms::BaseConcern

    attr_accessor :raw_content
  end
end

describe TransactionalSms::BaseConcern, type: :service do
  describe "#initialize" do
    context "user has valid mobile phone number" do
      it "should raise" do
        expect { SomeModule::TestSms.new(build(:rdv), build(:user)) }.not_to raise_error
      end
    end

    context "user has landline phone number" do
      let(:user) { build(:user, phone_number: "0130303030") }
      it "should raise" do
        expect { SomeModule::TestSms.new(build(:rdv), user) }.to \
          raise_error(InvalidMobilePhoneNumberError)
      end
    end
  end

  let(:user) { build(:user, address: "10 rue de Toulon, Lille") }
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
    let!(:territory77) { create(:territory, departement_number: "77") }
    let(:organisation) { create(:organisation, territory: territory77) }
    let(:rdv) { build(:rdv, organisation: organisation) }
    subject { SomeModule::TestSms.new(rdv, build(:user)).tags }
    it { should include("org-#{organisation.id}") }
    it { should include("dpt-77") }
    it { should include("test_sms") }
  end

  describe "#content" do
    let(:test_sms) { SomeModule::TestSms.new(build(:rdv), build(:user)) }
    subject { test_sms.content }
    context "remove accents and weird chars" do
      before { test_sms.raw_content = "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ" }
      it { should eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ") }
    end
    context "oe character" do
      before { test_sms.raw_content = "Nœuds les mînes" }
      it { should eq("Noeuds les mines") }
    end
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
