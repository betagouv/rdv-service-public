class DeleteSecretariatService < ActiveRecord::Migration[8.0]
  def up
    Service.where(name: "Secrétariat").delete_all
  end

  def down
    Service.find_or_create_by!(name: "Secrétariat", short_name: "Secrétariat")
  end
end
