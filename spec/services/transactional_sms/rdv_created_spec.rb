# frozen_string_literal: true

describe TransactionalSms::RdvCreated, type: :service do
  describe "#content" do
    context "with a basic rdv" do
      subject { described_class.new(OpenStruct.new(rdv.payload(:create)), user).content }

      let(:pmi) { build(:service, short_name: "PMI") }
      let(:motif) { build(:motif, service: pmi) }
      let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici") }
      let(:rdv) { build(:rdv, motif: motif, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
      let(:user) { build(:user) }

      it do
        expect(subject).to include("RDV PMI vendredi 10/12 à 13h10")
        expect(subject).to include("MDS Centre (10 rue d'ici)")
        expect(subject).to include("Infos et annulation")
      end
    end

    context "with a follow_up rdv" do
      it "contains referent name" do
        agent = create(:agent, first_name: "James", last_name: "Bond")
        user = create(:user, agents: [agent])
        motif = create(:motif, follow_up: true)
        rdv = create(:rdv, motif: motif, users: [user], agents: [agent])

        content = described_class.new(OpenStruct.new(rdv.payload(:create)), user).content

        expect(content).to include("James BOND")
      end
    end
  end
end
