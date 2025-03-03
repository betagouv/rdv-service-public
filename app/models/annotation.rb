class Annotation < ApplicationRecord
  belongs_to :user
  belongs_to :territory

  validates :content, presence: true
  validates :territory_id, uniqueness: { scope: :user_id }
end
