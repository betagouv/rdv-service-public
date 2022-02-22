# frozen_string_literal: true

describe Users::FileAttenteSms, type: :service do
  describe "#new_creneau_available" do
    subject { described_class.new_creneau_available(rdv, user).content }

    let(:rdv) { create(:rdv) }
    let(:user) { build(:user) }

    it do
      expect(subject).to include("Des créneaux se sont libérés plus tot")
      expect(subject).to include("Cliquez pour voir les disponibilités")
    end
  end
end
