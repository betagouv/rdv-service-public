class Motif < ApplicationRecord
  belongs_to :specialite

  validates :name, presence: true, uniqueness: { scope: :specialite }
  validates :specialite, presence: true
end
