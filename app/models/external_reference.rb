class ExternalReference < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :oauth_application, class_name: "Doorkeeper::Application"

  # TODO: ajouter un index
  validates :item_id, uniqueness: { scope: %i[item_type oauth_application_id] } # rubocop:disable Rails/UniqueValidationWithoutIndex
end
