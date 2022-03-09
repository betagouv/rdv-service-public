# frozen_string_literal: true

describe Users::FileAttenteSms, type: :service do
  describe "#new_creneau_available" do
    subject { described_class.new_creneau_available(rdv, user, token).content }

    let(:organisation) { build(:organisation, show_token_in_sms: true) }
    let(:rdv) { build(:rdv, id: 82, organisation: organisation) }
    let(:user) { build(:user) }
    let(:token) { "12324" }

    it do
      expect(subject).to include("Des créneaux se sont libérés plus tot")
      expect(subject).to include("Cliquez pour voir les disponibilités")
      expect(subject).to include("#{ENV['HOST']}/r/82/cr?tkn=12324")
    end

    context "when the organisation does not show the token in sms" do
      let!(:organisation) { build(:organisation, show_token_in_sms: false) }

      it do
        expect(subject).to include("#{ENV['HOST']}/r/82/cr")
        expect(subject).not_to include("tkn")
      end
    end
  end
end
