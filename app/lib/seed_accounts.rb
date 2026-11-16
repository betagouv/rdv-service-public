# Comptes de démo listés dans db/seeds/seed_accounts.yml.
#
# Ils sont proposés sur les pages de connexion agent et usagers, en dev et en review app.

class SeedAccounts
  Account = Data.define(:slug, :email, :label)

  def self.displayed?
    Rails.env.development? || ENV["IS_REVIEW_APP"] == "true"
  end

  def self.password
    ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"]
  end

  def self.agents
    yaml_config[:agents].transform_values { Account.new(slug:, **it) }
  end

  def self.users
    yaml_config[:users].transform_values { Account.new(slug:, **it) }
  end

  def self.yaml_config
    @yaml_config ||= YAML.load_file(Rails.root.join("db/seeds/seed_accounts.yml"), symbolize_names: true)
  end
end
