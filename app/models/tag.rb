class Tag < ApplicationRecord
  # Mixins
  has_paper_trail

  has_many :territory_tags, dependent: :destroy
  has_many :territories, through: :territory_tags

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
