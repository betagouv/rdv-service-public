# frozen_string_literal: true

class AddOrangeContactEveryoneAsEnumMemberForSmsConfiguration < ActiveRecord::Migration[6.0]
  def change
    add_enum_value :sms_provider, "orange_contact_everyone"
  end
end
