# frozen_string_literal: true

describe SmsSender, type: :service do
  describe "#content" do
    subject { test_sms.content }

    let(:test_sms) { described_class.new("RdvSoli", "0612345678", content, nil, nil, nil) }

    context "remove accents and weird chars" do
      let(:content) { "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ" }

      it { is_expected.to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ") }
    end

    context "oe character" do
      let(:content) { "Nœuds les mînes" }

      it { is_expected.to eq("Noeuds les mines") }
    end

    describe "instance name" do
      before { ENV["RDV_SOLIDARITES_INSTANCE_NAME"] = instance_name }

      after { ENV.delete("RDV_SOLIDARITES_INSTANCE_NAME") }

      let(:content) { "Contenu de test" }

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

  describe "receipt creation" do
    let(:rdv) { create(:rdv) }
    let(:user) { create(:user) }

    before do
      stub_netsize_ok
      described_class.perform_with("RdvSoli", "0612345678", "content", "netsize", "key", { event: "rdv_created", rdv: rdv, user: user })
    end

    it do
      receipt = Receipt.last
      expect(receipt).not_to be_nil
      expect(receipt).to have_attributes(
        event: "rdv_created",
        rdv: rdv,
        user: user,
        content: "content",
        sms_provider: "netsize"
      )
    end
  end
end
