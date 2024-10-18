class FixTerritorySmsConfigurationType < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      change_column :territories, :sms_configuration, :string, using: "sms_configuration::jsonb->>0"
    end
  end

  def down
    safety_assured do
      change_column :territories, :sms_configuration, :json, using: "to_json(sms_configuration::varchar)"
    end
  end
end
