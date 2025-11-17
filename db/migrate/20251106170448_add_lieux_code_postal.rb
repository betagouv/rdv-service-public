class AddLieuxCodePostal < ActiveRecord::Migration[7.2]
  def change
    add_column :lieux, :code_postal, :string

    reversible do |direction|
      direction.up do
        Lieu.all.find_each do |lieu|
          if lieu.address.present?
            lieu.update_columns(code_postal: Lieu.code_postal_from_address(lieu.address))
          end
        end
      end
    end
  end
end
