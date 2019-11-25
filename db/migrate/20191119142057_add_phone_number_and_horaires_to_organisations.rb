class AddPhoneNumberAndHorairesToOrganisations < ActiveRecord::Migration[6.0]
  def change
    remove_column :lieux, :horaires
    remove_column :lieux, :telephone
    add_column :organisations, :horaires, :text
    add_column :organisations, :phone_number, :string
  end
end
