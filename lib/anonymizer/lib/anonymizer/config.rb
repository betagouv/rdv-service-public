class AnonymizerConfigError < StandardError; end

module Anonymizer
  class Config
    def initialize(raw_config)
      raise AnonymizerConfigError, "top level should be a hash" unless raw_config.is_a?(Hash)

      @data = raw_config.with_indifferent_access
      raise AnonymizerConfigError, "rules should be a hash" unless @data[:rules].is_a?(Hash)
      raise AnonymizerConfigError, "truncated_tables should be an array" unless @data[:truncated_tables].is_a?(Array)
    end

    def rules = @data[:rules]

    def truncated_tables = @data[:truncated_tables]
  end
end
