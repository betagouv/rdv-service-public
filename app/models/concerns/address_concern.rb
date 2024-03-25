module AddressConcern
  extend ActiveSupport::Concern

  included do
    validates(
      :address,
      format: {
        with: /\A.+,\s.+,\s\d{5}\z/,
        message: "Le format correct est : 139 Rue de Bercy, Paris, 75012",
      },
      if: -> { address.present? }
    )
  end
end
