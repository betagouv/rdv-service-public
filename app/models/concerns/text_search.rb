module TextSearch
  extend ActiveSupport::Concern
  # Full Text Search support, using pg_search (https://github.com/Casecommons/pg_search).
  # See https://github.com/betagouv/rdv-solidarites.fr/pull/2791.
  #
  # Models including this concern need to have a :search_options class method returning
  # a configuration that will be used for the parameter of pg_search.
  #
  # This module has three roles:
  # 1. Declaring the base configuration for pg_search
  # 2. Special case email search by using the :email column
  #   This is needed to search for partial emails,
  #   e.g. when searching "john.doe@example" should return the row containing "john.doe@example.com".
  #   That wouldn't work with PG text search because PG actually parses the text token, and a valid email is
  #   saved as one token ("john.doe@example.com”") while an invalid email is several tokens ("john.doe", "@", "example")
  #   See https://www.postgresql.org/docs/current/textsearch-parsers.html
  #   If the search term looks like an email, we search on email only.
  #   We can't combine the query with full_text_search as it would lose the text ranking.
  # 3. Special case phone number search by normalizing the phone number
  #   We store phone numbers in e164 form.
  #   When searching "01 23 45 67", we want to return the row containing "+33123456789".

  included do
    include PgSearch::Model

    pg_search_scope :full_text_search, lambda { |query|
      {
        using: { tsearch: { prefix: true } },
        order_within_rank: "#{table_name}.updated_at desc",
        query: query,
      }.merge(search_options)
    }
  end

  class_methods do
    def search_by_text(term)
      return none if term.blank?

      term = clean_search_term(term)

      if columns.map(&:name).include?("email") && looks_like_email(term)
        where("\"#{table_name}\".\"email\" LIKE ?", "#{term}%")
      else
        full_text_search(term)
      end
    end

    def clean_search_term(term)
      term = term.strip
      term = I18n.transliterate(term)
      term = term.sub(/^0/, "+33").gsub(/\s/, "") if looks_like_phone_number(term)
      term
    end

    def looks_like_email(string)
      /^.*@.*$/.match?(string)
    end

    def looks_like_phone_number(string)
      /^(\+\d{2})?[\d ]{3,20}$/.match?(string)
    end
  end
end
