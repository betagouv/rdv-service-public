# frozen_string_literal: true

class AddSfrMail2smsEnumMemberForTerritorySmsConfiguration < ActiveRecord::Migration[6.0]
  def change
    add_enum_value :sms_provider, "sfr_mail2sms"
  end
end
