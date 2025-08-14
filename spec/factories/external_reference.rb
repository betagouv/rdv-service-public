FactoryBot.define do
  sequence(:external_id)
  sequence(:external_id_in_url)

  factory :external_reference do
    external_id {  generate(:external_id) }
    external_url { "monsuivisocial.anct.gouv.fr/users/#{generate(:external_id_in_url)}" }
    oauth_application
    territory
    item { create(:user) }
  end
end
