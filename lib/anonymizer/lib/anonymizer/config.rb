module Anonymizer
  class Config
    def initialize(yaml_path)
      @data = YAML.safe_load(yaml_path)
      raise "Invalid configuration file : should be a hash" unless @data.is_a?(Hash)

      @data = @data.with_indifferent_access
      raise "Invalid configuration file : rules should be a hash" unless @data[:rules].is_a?(Hash)
      raise "Invalid configuration file : truncated_tables should be an array" unless @data[:truncated_tables].is_a?(Array)
    end

    def rules = @data[:rules]

    def truncated_tables = @data[:truncated_tables]
  end
end
