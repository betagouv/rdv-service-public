class AddVisioLocationType < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :location_type, "visio"
  end
end
