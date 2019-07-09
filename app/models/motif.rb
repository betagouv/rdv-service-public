class Motif < ApplicationRecord
  belongs_to :organisation
  belongs_to :specialite
  has_many :rdvs, dependent: :restrict_with_exception
  has_and_belongs_to_many :plage_ouvertures

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :color, :default_duration_in_min, presence: true
  validates :max_users_limit, numericality: { greater_than_or_equal_to: 1 }, allow_nil: true
end
