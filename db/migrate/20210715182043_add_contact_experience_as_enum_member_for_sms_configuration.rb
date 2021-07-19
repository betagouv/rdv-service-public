# frozen_string_literal: true

class AddContactExperienceAsEnumMemberForSmsConfiguration < ActiveRecord::Migration[6.0]
  def change
    add_enum_value :sms_provider, "contact_experience"
  end
end
