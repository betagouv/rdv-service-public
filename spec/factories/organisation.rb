FactoryBot.define do
  sequence(:orga_name) { |n| "Organisation n°#{n}" }

  factory :organisation do
    name { generate(:orga_name) }

    before(:create) do |organisation, _evaluator|
      if organisation.pros.empty?
        organisation.pros << create(:pro)
      end
    end
  end
end
