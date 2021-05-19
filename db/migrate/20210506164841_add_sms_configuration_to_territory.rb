# frozen_string_literal: true

class AddSmsConfigurationToTerritory < ActiveRecord::Migration[6.0]
  def change
    create_enum :sms_provider, %w[netsize send_in_blue]

    add_column :territories, :sms_provider, :sms_provider
    add_column :territories, :sms_configuration, :json

    up_only do
      Territory.all.map do |territory|
        territory.sms_provider = "netsize"
        territory.sms_configuration = {
          api_url: "https://europe.ipx.com/restapi/v1/sms/send",
          user_pwd: ENV["NETSIZE_API_USERPWD"]
        }
        territory.save
      end
    end
  end
end
