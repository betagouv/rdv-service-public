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
    subject { SomeModule::TestSms.new(OpenStruct.new(rdv.payload), user).rdv_footer }

    describe "depending on motif" do
      let(:rdv) { build(:rdv, motif: motif, users: [user], starts_at: 5.days.from_now) }

      context "when regular Rdv" do
        let(:motif) { build(:motif, :at_public_office) }

        it { is_expected.to include(rdv.address) }
      end

      context "when Rdv is at home" do
        let(:motif) { build(:motif, :at_home) }

        it do
          expect(subject).to include("RDV à domicile")
          expect(subject).to include(rdv.address)
        end
      end

      context "when Rdv is by phone" do
        let(:motif) { build(:motif, :by_phone) }

        it do
          expect(subject).to include("RDV Téléphonique")
          expect(subject).to include(rdv.address)
        end
      end
    end

    describe "depending on phone" do
      let(:rdv) { build(:rdv, lieu: lieu, organisation: organisation, users: [user], starts_at: 5.days.from_now) }
      let(:lieu) { build(:lieu, phone_number: lieu_phone_number) }
      let(:organisation) { build(:organisation, phone_number: organisation_phone_number) }

      context "when both have a phone number" do
        let(:lieu_phone_number) { "0123456789" }
        let(:organisation_phone_number) { "0987654321" }

        it { expect(subject).to include(" / 0123456789") }
      end

      context "when only organisation has a phone number" do
        let(:lieu_phone_number) { nil }
        let(:organisation_phone_number) { "0987654321" }

        it { expect(subject).to include(" / 0987654321") }
      end

      context "when none have a phone number" do
        let(:lieu_phone_number) { nil }
        let(:organisation_phone_number) { nil }

        it { expect(subject).not_to include(" / ") }
      end
    end
  end

  describe "#tags" do
    subject { SomeModule::TestSms.new(OpenStruct.new(rdv.payload), build(:user)).tags }

    let!(:territory77) { create(:territory, departement_number: "77") }
    let(:organisation) { create(:organisation, territory: territory77) }
    let(:rdv) { build(:rdv, organisation: organisation) }

    it do
      expect(subject).to include("org-#{organisation.id}")
      expect(subject).to include("dpt-77")
      expect(subject).to include("test_sms")
    end
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

    describe "instance name" do
      before do
        ENV["RDV_SOLIDARITES_INSTANCE_NAME"] = instance_name
        test_sms.raw_content = "Contenu de test"
      end

      after { ENV.delete("RDV_SOLIDARITES_INSTANCE_NAME") }

      context "when instance name is blank" do
        let(:instance_name) { "" }

        it { is_expected.to eq("Contenu de test") }
      end

      context "when instance name is set" do
        let(:instance_name) { "TEST INSTANCE" }

        it { is_expected.to eq("TEST INSTANCE\nContenu de test") }
      end
    end
  end

  describe "#send!" do
    let(:sms) { SomeModule::TestSms.new(OpenStruct.new(build(:rdv).payload), build(:user)) }

    it "calls send service" do
      expect(SendTransactionalSmsService).to receive(:perform_with)
      sms.send!
    end
  end
end
