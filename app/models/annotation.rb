class Annotation < ApplicationRecord
  belongs_to :user
  belongs_to :territory

  validates :content, presence: true
end
