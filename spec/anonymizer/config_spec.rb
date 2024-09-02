RSpec.describe Anonymizer::Config do
  context "correct" do
    let(:raw_config) do
      {
        "tables" => [
          {
            "table_name" => "users",
            "class_name" => "User",
            "anonymized_column_names" => %w[first_name last_name],
          },
          {
            "table_name" => "blah",
            "truncated" => true,
          },
          {
            "table_name" => "test",
            "truncated" => true,
          },
        ],
      }
    end

    it "works" do
      config = described_class.new(raw_config)
      expect(config.truncated_table_names).to eq %w[blah test]
      # expect(config.table_config_by_name("users").class_name).to eq("User")
      expect(config.table_config_by_name("users").anonymized_column_names).to eq %w[first_name last_name]
    end
  end

  context "the config YAML is not a hash" do
    it "raises an error" do
      expect { described_class.new([]) }.to raise_error(AnonymizerConfigError, "top level should be a hash")
    end
  end

  context "the config YAML is missing the tables key" do
    it "raises an error" do
      expect { described_class.new({ "something" => [], "blah" => [] }) }.to raise_error(AnonymizerConfigError, "tables should be an array")
    end
  end
end
