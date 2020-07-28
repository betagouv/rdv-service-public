module User::SearchableConcern
  extend ActiveSupport::Concern

  PHONE_REGEX = /^(\+\d{2})?[\d ]{3,20}$/.freeze

  included do
    pg_search_scope(
      :search_by_text,
      lambda { |query|
        if PHONE_REGEX.match?(query)
          {
            using: { tsearch: { prefix: true } },
            against: [:phone_number_formatted],
            query: query.sub(/^0/, '+33').gsub(/\s/, '')
          }
        else
          {
            ignoring: :accents,
            using: { tsearch: { prefix: true } },
            against: [:first_name, :last_name, :birth_name, :email],
            query: query
          }
        end
      }
    )
  end
end
