# frozen_string_literal: true

describe TransactionalSms::FileAttente, type: :service do
  describe "#content" do
    subject { described_class.new(OpenStruct.new(rdv.payload(:update)), user).content }

    let(:rdv) { build(:rdv) }
    let(:user) { build(:user) }

    it do
      expect(subject).to include("Des créneaux se sont libérés plus tot")
      expect(subject).to include("Cliquez pour voir les disponibilités")
    end
  end
end
