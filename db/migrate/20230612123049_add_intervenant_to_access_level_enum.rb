class AddIntervenantToAccessLevelEnum < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :access_level, "intervenant"
  end
end
