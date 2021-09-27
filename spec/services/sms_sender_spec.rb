# frozen_string_literal: true

describe SmsSender, type: :service do
  describe "#content" do
    subject { test_sms.content }

    let(:test_sms) { described_class.new("0612345678", content, [], nil, nil) }

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

  describe "#splitted_content" do
    it "return an empty array for an empty content" do
      expect(described_class.splitted_content("")).to eq([])
    end

    it "return string when string length is less than max given" do
      expect(described_class.splitted_content("a short string", 20)).to eq(["a short string"])
    end

    it "return two strings when string length is over max given" do
      expect(described_class.splitted_content("one word", 4)).to eq(%w[one word])
    end

    it "strip blank at the end of bloc" do
      expect(described_class.splitted_content("one word", 4)).to eq(%w[one word])
    end

    it "strip blank at the beginning of bloc" do
      expect(described_class.splitted_content("word one", 4)).to eq(%w[word one])
    end

    it "dont cut word" do
      expect(described_class.splitted_content("an ubber string", 12)).to eq(["an ubber", "string"])
    end
  end
end
