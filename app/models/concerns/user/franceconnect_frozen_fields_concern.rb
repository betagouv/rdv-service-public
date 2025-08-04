module User::FranceconnectFrozenFieldsConcern
  # Champs de l'identité pivot FranceConnect
  FROZEN_FIELDS = %i[first_name birth_name birth_date].freeze

  extend ActiveSupport::Concern

  included do
    validate :prevent_frozen_fields_from_changing
  end

  def frozen_by_franceconnect?(attribute)
    logged_once_with_franceconnect? && FROZEN_FIELDS.include?(attribute)
  end

  protected

  def prevent_frozen_fields_from_changing
    # Cette validation empêche un usager ou un agent de modifier les champs de l'identité pivot.
    # Pendant un login FranceConnect, il est légitime et même souhaitable que ces champs soient
    # mis à jour, et donc on veut désactiver cette validation dans ce contexte.
    return if validation_context == :france_connect_login

    return true unless logged_once_with_franceconnect_was

    changed_fields = FROZEN_FIELDS.select { send("will_save_change_to_#{_1}?") }
    return true if changed_fields.empty?

    changed_fields.each { errors.add(_1, :franceconnect_frozen_field_cannot_change) }
  end
end
