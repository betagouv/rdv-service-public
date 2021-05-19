# frozen_string_literal: true

describe TransactionalSms::Builder, type: :service do
  describe "#with" do
    subject { described_class.with(rdv, user, event_type) }

    let(:rdv) { build(:rdv) }
    let(:user) { build(:user) }

    context "rdv_created" do
      let(:event_type) { :rdv_created }

      it { is_expected.to be_an_instance_of(TransactionalSms::RdvCreated) }
    end

    context "file_attente" do
      let(:event_type) { :file_attente }

      it { is_expected.to be_an_instance_of(TransactionalSms::FileAttente) }
    end

    context "rdv_cancelled" do
      let(:event_type) { :rdv_cancelled }

      it { is_expected.to be_an_instance_of(TransactionalSms::RdvCancelled) }
    end

    context "reminder" do
      let(:event_type) { :reminder }

      it { is_expected.to be_an_instance_of(TransactionalSms::Reminder) }
    end
  end
end
