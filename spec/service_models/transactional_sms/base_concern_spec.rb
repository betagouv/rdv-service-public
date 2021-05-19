# frozen_string_literal: true

module SomeModule
  class TestSms
    include TransactionalSms::BaseConcern

    attr_accessor :raw_content
  end
end

describe TransactionalSms::BaseConcern, type: :service do
  let(:user) { build(:user, address: "10 rue de Toulon, Lille") }

  describe "#initialize" do
    context "user has valid mobile phone number" do
      it "raises" do
        expect { SomeModule::TestSms.new(build(:rdv), build(:user)) }.not_to raise_error
      end
    end

    context "user has landline phone number" do
      let(:user) { build(:user, phone_number: "0130303030") }

      it "raises" do
        expect { SomeModule::TestSms.new(build(:rdv), user) }.to \
          raise_error(InvalidMobilePhoneNumberError)
      end
    end
  end

  describe "#rdv_footer" do
    subject { SomeModule::TestSms.new(rdv, user).rdv_footer }

    let(:rdv) { build(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now) }

    context "when regular Rdv" do
      let(:motif) { build(:motif, :at_public_office) }

      it { is_expected.to include(rdv.address) }
    end

    context "when Rdv is at home" do
      let(:motif) { build(:motif, :at_home) }

      it { is_expected.to include("RDV à domicile") }
      it { is_expected.to include(rdv.address) }
    end

    context "when Rdv is by phone" do
      let(:motif) { build(:motif, :by_phone) }

      it { is_expected.to include("RDV Téléphonique") }
      it { is_expected.to include(rdv.address) }
    end
  end

  describe "#tags" do
    subject { SomeModule::TestSms.new(rdv, build(:user)).tags }

    let!(:territory77) { create(:territory, departement_number: "77") }
    let(:organisation) { create(:organisation, territory: territory77) }
    let(:rdv) { build(:rdv, organisation: organisation) }

    it { is_expected.to include("org-#{organisation.id}") }
    it { is_expected.to include("dpt-77") }
    it { is_expected.to include("test_sms") }
  end

  describe "#content" do
    subject { test_sms.content }

    let(:test_sms) { SomeModule::TestSms.new(build(:rdv), build(:user)) }

    context "remove accents and weird chars" do
      before { test_sms.raw_content = "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ" }

      it { is_expected.to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ") }
    end

    context "oe character" do
      before { test_sms.raw_content = "Nœuds les mînes" }

      it { is_expected.to eq("Noeuds les mines") }
    end
  end

  describe "#send!" do
    let(:sms) { SomeModule::TestSms.new(build(:rdv), build(:user)) }

    before { allow(SendTransactionalSmsService).to receive(:perform_with).with(sms) }

    it "calls send service" do
      sms.send!
    end
  end
end
