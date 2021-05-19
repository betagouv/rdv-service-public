# frozen_string_literal: true

module User::FranceconnectFrozenFieldsConcern
  FROZEN_FIELDS = %i[first_name birth_name birth_date].freeze

  extend ActiveSupport::Concern

  included do
    validate :prevent_frozen_fields_from_changing
  end

  protected

  def prevent_frozen_fields_from_changing
    return true unless logged_once_with_franceconnect_was

    changed_fields = FROZEN_FIELDS.select { send("will_save_change_to_#{_1}?") }
    return true if changed_fields.empty?

    changed_fields.each { errors.add(_1, :franceconnect_frozen_field_cannot_change) }
  end
end
