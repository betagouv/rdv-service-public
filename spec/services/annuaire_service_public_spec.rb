RSpec.describe AnnuaireServicePublic do
  describe "#nom" do
    let(:siret) { "13002603200016" }

    before do
      AnnuaireServicePublicStubs.stub_siret_as_anct(siret, self)
    end

    it "indique le nom de la structure" do
      expect(described_class.new(siret).nom).to eq "Agence nationale de la cohésion des territoires (ANCT)"
    end

    it "n'appelle l'api qu'une fois" do
      client = described_class.new(siret)
      client.nom
      expect(Faraday).not_to receive(:get)
      client.nom
    end
  end

  describe "#mairie" do
    subject { described_class.new(siret).mairie? }

    context "pour une mairie" do
      let(:siret) { "21600660100019" }

      before do
        AnnuaireServicePublicStubs.stub_siret_as_mairie(siret, self)
      end

      it { is_expected.to be_truthy }
    end

    context "pour une autre structure" do
      let(:siret) { "13002603200016" }

      before do
        AnnuaireServicePublicStubs.stub_siret_as_anct(siret, self)
      end

      it { is_expected.to be_falsey }
    end
  end

  context "si l'api ne répond pas" do
    before do
      allow(Faraday).to receive(:get).and_raise(Faraday::TimeoutError)
    end

    it "renvoie nil et notifie Sentry" do
      expect(described_class.new("21600660100019").nom).to be_nil
      expect(sentry_events.last.exception.values.first.value).to eq("timeout (Faraday::TimeoutError)")
    end
  end
end
