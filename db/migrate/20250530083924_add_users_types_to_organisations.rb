class AddUsersTypesToOrganisations < ActiveRecord::Migration[7.1]
  def change
    add_column :organisations, :online_booking_for_particuliers, :boolean, null: false, default: true
    add_column :organisations, :online_booking_for_professionnels, :boolean, null: false, default: false

    change_column_comment :organisations, :online_booking_for_particuliers, from: nil, to: <<~COMMENT
      Indique que l'organisation gère des rendez-vous avec des particuliers, et donc qu'on propose le bouton FranceConnect lors de la prise de rendez-vous en ligne.
    COMMENT

    change_column_comment :organisations, :online_booking_for_professionnels, from: nil, to: <<~COMMENT
      Indique que l'organisation gère des rendez-vous avec des professionnels, et donc qu'on propose le bouton ProConnect lors de la prise de rendez-vous en ligne.
    COMMENT
  end
end
