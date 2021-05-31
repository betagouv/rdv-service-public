# frozen_string_literal: true

describe TransactionalSms::RdvUpdated, type: :service do
  let(:pmi) { build(:service, short_name: "PMI") }
  let(:motif) { build(:motif, service: pmi) }
  let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici") }
  let(:rdv) { build(:rdv, motif: motif, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
  let(:user) { build(:user) }

  describe "#content" do
    subject { described_class.new(rdv, user).content }

    it { is_expected.to include("RDV modifié: PMI vendredi 10/12 à 13h10") }
    it { is_expected.to include("MDS Centre (10 rue d'ici)") }
    it { is_expected.to include("Infos et annulation") }
  end
end
