class AddVariousNotNullConstraints < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        # Nous avons en base 135 938 / 5 105 235 receipts dans ce cas, tous
        # avant le 12 avril 2022, on peut donc les virer.
        Receipt.where(user_id: nil).delete_all
      end
    end

    safety_assured do
      change_column_null :receipts, :user_id, false
      change_column_null :territory_services, :territory_id, false
      change_column_null :territory_services, :service_id, false
      change_column_null :zones, :level, false
      change_column_null :zones, :city_name, false
      change_column_null :zones, :city_code, false
      change_column_null :webhook_endpoints, :secret, false
      change_column_null :services, :name, false
      change_column_null :services, :short_name, false
      change_column_null :plage_ouvertures, :title, false
      change_column_null :organisations, :name, false
      change_column_null :motifs, :name, false
      change_column_null :motifs, :color, false
      change_column_null :motifs, :min_public_booking_delay, false
      change_column_null :motifs, :max_public_booking_delay, false
      change_column_null :agent_services, :agent_id, false
      change_column_null :agent_services, :service_id, false
      change_column_null :users, :first_name, false
      change_column_null :users, :last_name, false
      change_column_null :users, :created_through, false
    end
  end
  # rubocop:enable Metrics/MethodLength
end
