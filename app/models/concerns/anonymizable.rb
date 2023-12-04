module Anonymizable
  extend ActiveSupport::Concern

  class_methods do
    def anonymized_column_names
      raise "This method should be implemented to list all the columns that need to be anonymized"
    end

    # Liste des données qui ne seront pas anonymisées
    def non_anonymized_column_names
      []
    end
  end
end
