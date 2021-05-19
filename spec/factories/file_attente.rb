# frozen_string_literal: true

FactoryBot.define do
  factory :file_attente do
    rdv { create(:organisation) }
    user { create(:user) }
  end
end
