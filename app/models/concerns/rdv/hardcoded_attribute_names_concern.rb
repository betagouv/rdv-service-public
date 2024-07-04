# Workaround to calling Rdv.attribute_names in form concerns so that the boot
# does not crash when the database is not accessible

module Rdv::HardcodedAttributeNamesConcern
  extend ActiveSupport::Concern

  HARDCODED_ATTRIBUTE_NAMES = %w[
    id
    starts_at
    organisation_id
    created_at
    updated_at
    cancelled_at
    motif_id
    uuid
    context
    lieu_id
    ends_at
    name
    max_participants_count
    users_count
    status
    created_by_id
    created_by_type
  ].freeze

  class_methods do
    def hardcoded_attribute_names = HARDCODED_ATTRIBUTE_NAMES
  end
end
