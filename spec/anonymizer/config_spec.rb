RSpec.describe Anonymizer::Config do
  context "correct" do
    let(:raw_config) do
      {
        "truncated_tables" => %w[blah test],
        "rules" => {
          users: {
            class_name: "User",
            anonymized_column_names: %w[first_name last_name],
          },
        },
      }
    end

    it "works" do
      config = described_class.new(raw_config)
      expect(config.truncated_tables).to eq %w[blah test]
      expect(config.rules[:users][:class_name]).to eq("User")
      expect(config.rules[:users][:anonymized_column_names]).to eq %w[first_name last_name]
    end
  end

  context "the config YAML is not a hash" do
    it "raises an error" do
      expect { described_class.new([]) }.to raise_error(AnonymizerConfigError, "top level should be a hash")
    end
  end

  context "the config YAML is missing rules" do
    it "raises an error" do
      expect { described_class.new({ "truncated_tables" => [], "blah" => [] }) }.to raise_error(AnonymizerConfigError, "rules should be a hash")
    end
  end
end
