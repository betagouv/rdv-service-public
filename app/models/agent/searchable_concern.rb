# frozen_string_literal: true

module Agent::SearchableConcern
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model
    pg_search_scope(
      :search_by_text,
      ignoring: :accents,
      using: { tsearch: { prefix: true } },
      against: %i[first_name last_name email]
    )
  end
end
