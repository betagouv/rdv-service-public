class MigrateMotifsByPhoneToLocationType < ActiveRecord::Migration[6.0]
  def up
    Motif.where(by_phone: true).update_all(location_type: :phone)
  end
end
