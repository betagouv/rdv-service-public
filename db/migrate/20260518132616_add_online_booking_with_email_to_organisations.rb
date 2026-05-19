class AddOnlineBookingWithEmailToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :online_booking_with_email, :boolean, default: true, null: false

    change_column_comment(
      :organisations,
      :online_booking_with_email,
      from: nil,
      to: "Indique si on autorise ou non les usagers à se connecter via leur adresse email lors de la prise de rendez-vous en ligne."
    )
  end
end
