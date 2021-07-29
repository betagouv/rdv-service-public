# frozen_string_literal: true

class AddCleverTechnologiesEnumMemberForTerritorySmsConfiguration < ActiveRecord::Migration[6.0]
  def change
    add_enum_value :sms_provider, "clever_technologies"
  end
end
