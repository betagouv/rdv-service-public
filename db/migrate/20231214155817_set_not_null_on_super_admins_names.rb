class SetNotNullOnSuperAdminsNames < ActiveRecord::Migration[7.0]
  def change
    # Cette table est peu lue donc ce n'est pas dangereux qu'elle soit bloquée le temps de la migration
    safety_assured do
      change_column_null :super_admins, :first_name, false
      change_column_null :super_admins, :last_name, false
    end
  end
end
