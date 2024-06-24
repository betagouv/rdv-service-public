require_relative "lib/anonymizer/version"

Gem::Specification.new do |spec|
  spec.name = "anonymizer"
  spec.version = Anonymizer::VERSION
  spec.authors = ["RDV Service Public"]

  spec.summary = "Anonymize ActiveRecord data"
  spec.description = "Anonymize ActiveRecord data"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = "https://github.com/betagouv/rdv-service-public/"
  spec.metadata["rubygems_mfa_required"] = "true" # this is auto-added by Rubocop
end
