# frozen_string_literal: true

module Agent::SearchConcern
  extend ActiveSupport::Concern

  included do
    include TextSearch
    def self.search_against
      {
        last_name: "A",
        first_name: "B",
        email: "D",
        id: "D",
      }
    end
  end
end
