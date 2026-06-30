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
    def search_by_text(search_query)
      search_query = search_query.strip
      return none if search_query.blank?

      if column_names.include?("email") && looks_like_email(search_query)
        where("\"#{table_name}\".\"email\" LIKE ?", "#{search_query}%")
      elsif self == User && looks_like_phone_number(search_query)
        search_by_phone_number(search_query)
      elsif self == User && looks_like_an_id(search_query)
        # Certains départements cherchent les usagers via l'ID RDV-S stocké dans leur logiciel de gestion
        where(id: search_query)
      else
        full_text_search(I18n.transliterate(search_query))
      end
    end

    def looks_like_email(string)
      /^.*@.*$/.match?(string)
    end

    def looks_like_phone_number(string)
      return false unless string.starts_with?("+") || string.starts_with?("0")

      /^(\+\d{2})?[\d ]{3,20}$/.match?(string)
    end

    def search_by_phone_number(search_query)
      international_number = search_query.sub(/^0/, "+33").gsub(/\s/, "")
      where_column_starts_with("phone_number_formatted", international_number)
    end

    def where_column_starts_with(columns_name, query)
      prefix_next = query.dup
      prefix_next[-1] = (prefix_next[-1].ord + 1).chr
      where(columns_name => query...prefix_next)
    end

    def looks_like_an_id(string)
      /^\d{3,}$/.match?(string)
    end
  end
end
