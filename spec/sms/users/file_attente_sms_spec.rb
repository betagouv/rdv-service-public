# frozen_string_literal: true

describe Users::FileAttenteSms, type: :service do
  describe "#new_creneau_available" do
    subject { described_class.new_creneau_available(rdv, user, token).content }

    let(:rdv) { build(:rdv, id: 82) }
    let(:user) { build(:user) }
    let(:token) { "12324" }

    it do
      expect(subject).to include("Des créneaux se sont libérés plus tot")
      expect(subject).to include("Cliquez pour voir les disponibilités")
      expect(subject).to include("#{ENV['HOST']}/users/rdvs/82/creneaux?tkn=12324")
    end
  end
end
