RSpec.describe Anonymizer::Config do
  context "correct" do
    before { allow(YAML).to receive(:load_file).and_return(config) }

    let(:config) do
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
      config = described_class.new("path.yml")
      expect(config.truncated_tables).to eq %w[blah test]
      expect(config.rules[:users][:class_name]).to eq("User")
      expect(config.rules[:users][:anonymized_column_names]).to eq %w[first_name last_name]
    end
  end

  context "file does not exist" do
    it "raises an error" do
      expect { described_class.new("not_a_file.yml") }.to raise_error(Errno::ENOENT)
    end
  end

  context "the config YAML is not a hash" do
    before { allow(YAML).to receive(:load_file).and_return([]) }

    it "raises an error" do
      expect { described_class.new("path.yml") }.to raise_error(RuntimeError, "Invalid configuration file : should be a hash")
    end
  end

  context "the config YAML is missing rules" do
    before { allow(YAML).to receive(:load_file).and_return({ "truncated_tables" => [], "blah" => [] }) }

    it "raises an error" do
      expect { described_class.new("path.yml") }.to raise_error(RuntimeError, "Invalid configuration file : rules should be a hash")
    end
  end
end
