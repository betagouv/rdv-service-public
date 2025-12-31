FactoryBot.define do
  sequence(:tag_name) { |n| "Tag #{n}" }

  factory :tag do
    name { generate(:tag_name) }
  end
end
