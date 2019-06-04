class Motif < ApplicationRecord
  belongs_to :specialite

  validates :name, :specialite, presence: true
end
