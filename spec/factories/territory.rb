FactoryBot.define do
  sequence(:territory_name) { |n| "Territoire n°#{n}" }
  sequence(:departement_number)

  factory :territory do
    name { generate(:territory_name) }
    departement_number { generate(:departement_number).to_s.rjust(2, "0") }
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
    after(:create) do |territory, _|
      # Les contraintes de validations sur les noms spéciaux obligent à faire un update_columns ici
      territory.update_columns(name: Territory::CNFS_NAME) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
