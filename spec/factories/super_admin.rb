# frozen_string_literal: true

FactoryBot.define do
  sequence(:super_admin_email) { |n| "super_admin_#{n}@lapin.fr" }

  factory :super_admin do
    email { generate(:super_admin_email) }
  end
end
