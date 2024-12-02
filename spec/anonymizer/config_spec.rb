RSpec.describe Anonymizer::Config do
  context "valid config with various rules" do
    let(:raw_config) do
      {
        "tables" => [
          {
            "table_name" => "users",
            "anonymized_column_names" => %w[first_name last_name],
            "non_anonymized_column_names" => %w[organisation_id],
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

    it "instanciates without errors and exposes rules" do
      config = described_class.new(raw_config)
      expect(config.truncated_table_names).to eq %w[blah test]
      expect(config.table_config_by_name("users").anonymized_column_names).to eq %w[first_name last_name]
      expect(config.table_config_by_name("users").non_anonymized_column_names).to eq %w[organisation_id]
    end
  end

  context "the config YAML is not a hash" do
    it "raises an error upon initialization" do
      expect { described_class.new([]) }.to raise_error(Anonymizer::ConfigError, "top level should be a hash")
    end
  end

  context "the config YAML is missing the tables key" do
    it "raises an error upon initialization" do
      expect { described_class.new({ "something" => [], "blah" => [] }) }.to raise_error(Anonymizer::ConfigError, "tables should be an array")
    end
  end

  context "a table does not have rules nor is truncated" do
    let(:raw_config) do
      {
        "tables" => [
          {
            "table_name" => "users",
          },
        ],
      }
    end

    it "raises an error upon initialization" do
      expect { described_class.new(raw_config) }.to raise_error(Anonymizer::ConfigError, "table users should have anonymization rules or be truncated")
    end
  end

  context "a table has both anonymization rules and is truncated" do
    let(:raw_config) do
      {
        "tables" => [
          {
            "table_name" => "users",
            "anonymized_column_names" => %w[first_name last_name],
            "truncated" => true,
          },
        ],
      }
    end

    it "raises an error upon initialization" do
      expect { described_class.new(raw_config) }.to raise_error(Anonymizer::ConfigError, "table users cannot be truncated and have anonymization rules")
    end
  end
end
