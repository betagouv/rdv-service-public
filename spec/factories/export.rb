FactoryBot.define do
  factory :export do
    export_type { Export::RDV_EXPORT }
    agent
    file_name { Faker::File.file_name }
    organisation_ids { [111, 222, 333] }
    options { {} }
  end
end
