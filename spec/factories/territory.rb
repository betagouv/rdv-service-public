FactoryBot.define do
  factory :territory do
    name { Territory::DEPARTEMENTS_NAMES.fetch(departement_number) }
    departement_number { random_value_in(Territory::DEPARTEMENTS_NAMES.keys) }
    sms_provider { "netsize" }
    sms_configuration { "a_key" }
  end

  trait :mairies do
    after(:create) do |territory, _|
      # Les contraintes de validations sur les noms spéciaux obligent à faire un update_columns ici
      territory.update_columns(name: Territory::MAIRIES_NAME) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  trait :conseillers_numeriques do
    departement_number { Territory::CN_DEPARTEMENT_NUMBER }
    after(:create) do |territory, _|
      # Les contraintes de validations sur les noms spéciaux obligent à faire un update_columns ici
      territory.update_columns(name: Territory::CNFS_NAME) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
