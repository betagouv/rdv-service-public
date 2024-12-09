require_relative "lib/omniauth-rdv-service-public/version"

Gem::Specification.new do |gem|
  gem.version       = OmniAuth::RdvServicePublic::VERSION
  gem.authors       = ["RDV Service Public"]
  gem.description   = "Une stratégie OmniAuth pour RDV Service Public"
  gem.summary       = "Une stratégie OmniAuth pour RDV Service Public"

  gem.name          = "omniauth-rdv-service-public"
  gem.require_paths = ["lib"]

  gem.add_dependency "omniauth", "~> 2.0"
  gem.add_dependency "omniauth-oauth2", "~> 1.8"
  gem.metadata["source_code_uri"] = "https://github.com/betagouv/rdv-service-public/tree/production/lib/omniauth-rdv-service-public"
  gem.metadata["rubygems_mfa_required"] = "true" # this is auto-added by Rubocop
  gem.required_ruby_version = ">= 3.1.0"
end
