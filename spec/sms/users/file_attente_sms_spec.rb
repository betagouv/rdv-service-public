# frozen_string_literal: true

describe Users::FileAttenteSms, type: :service do
  describe "#new_creneau_available" do
    subject { described_class.new_creneau_available(rdv, user, token).content }

    let(:organisation) { build(:organisation) }
    let(:rdv) { build(:rdv, id: 82, organisation: organisation) }
    let(:user) { build(:user) }
    let(:token) { "12324" }

    it do
      expect(subject).to include("RDV Service 1: des créneaux se sont libérés")
      expect(subject).to include("Pour voir les disponibilités")
      expect(subject).to include("http://www.rdv-solidarites-test.localhost/r/82/cr?tkn=12324")
    end
  end
end
