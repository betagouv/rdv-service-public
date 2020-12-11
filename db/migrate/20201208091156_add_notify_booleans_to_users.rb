class AddNotifyBooleansToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :notify_by_sms, :bool, default: true
    add_column :users, :notify_by_email, :bool, default: true
  end
end
