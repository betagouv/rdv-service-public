# frozen_string_literal: true

class ChangeTerritorySmsConfigurationFormat < ActiveRecord::Migration[6.0]
  def change
    Territory.all.each do |territory|
      if territory.sms_configuration && territory.sms_configuration["user_pwd"]
        territory.sms_configuration = territory.sms_configuration["user_pwd"]
      end
      territory.save
    end
  end
end
