class FileAttente < ApplicationRecord
  belongs_to :rdv
  belongs_to :user
  validates :rdv, uniqueness: { scope: :user }
end
