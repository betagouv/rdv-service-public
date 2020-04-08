class CreateWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :webhook_endpoints do |t|
      t.string :target_url, null: false
      t.string :secret
      t.references :organisation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
