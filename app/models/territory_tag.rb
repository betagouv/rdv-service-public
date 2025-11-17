class TerritoryTag < ApplicationRecord
  # Mixins
  has_paper_trail

  belongs_to :territory
  belongs_to :tag
end
