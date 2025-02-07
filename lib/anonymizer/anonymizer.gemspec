require_relative "lib/anonymizer/version"

Gem::Specification.new do |spec|
  spec.name = "sql-anonymizer"
  spec.version = Anonymizer::VERSION
  spec.authors = ["RDV Service Public"]

  spec.summary = "Erase personal data from Postgres tables to use them for stats"
  spec.description = "Erase personal data from Postgres tables to use them for stats"
  spec.required_ruby_version = ">= 3.3.0"
  spec.files = Dir["lib/**/*.rb"]

  spec.add_dependency "activerecord", ">= 7.0"

  spec.metadata["source_code_uri"] = "https://github.com/betagouv/rdv-service-public/"
  spec.metadata["rubygems_mfa_required"] = "true" # this is auto-added by Rubocop
end
