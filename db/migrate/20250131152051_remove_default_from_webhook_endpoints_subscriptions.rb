class RemoveDefaultFromWebhookEndpointsSubscriptions < ActiveRecord::Migration[7.1]
  def up
    # L'opération bloque les écritures pendant 2ms, c'est acceptable
    safety_assured do
      change_column_null :webhook_endpoints, :subscriptions, false
      change_column_default :webhook_endpoints, :subscriptions, []
    end
  end

  def down
    # L'opération bloque les écritures pendant 2ms, c'est acceptable
    safety_assured do
      change_column_null :webhook_endpoints, :subscriptions, true
      change_column_default :webhook_endpoints, :subscriptions, %w[rdv absence plage_ouverture]
    end
  end
end
