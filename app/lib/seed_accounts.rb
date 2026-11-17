# Comptes de démo listés dans db/seeds/seed_accounts.yml.
#
# Ils sont proposés sur les pages de connexion agent et usagers, en dev et en review app.

class SeedAccounts
  PATH = Rails.root.join("db/seeds/seed_accounts.yml").freeze

  Account = Data.define(:email, :label)

  def self.displayed?
    Rails.env.development? || ENV["IS_REVIEW_APP"] == "true"
  end

  def self.filter(kind:, domain:)
    return [] unless displayed?

    yaml_config[kind]
      .values
      .select { _1[:domain].blank? || _1[:domain] == domain.id }
      .map { Account.new(**_1.slice(:email, :label)) }
  end

  def self.yaml_config
    if Rails.env.development?
      # Pas de mémoïsation en dev : on veut voir les changements du YAML sans redémarrer le serveur
      YAML.load_file(PATH, symbolize_names: true)
    else
      @yaml_config ||= YAML.load_file(PATH, symbolize_names: true)
    end
  end
end
