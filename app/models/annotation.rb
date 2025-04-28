class Annotation < ApplicationRecord
  belongs_to :user
  belongs_to :territory

  validates :content, presence: true
  validates :territory_id, uniqueness: { scope: :user_id }

  def self.upsert!(content, user:, territory:)
    if content.present?
      annotation = find_or_initialize_by(user:, territory:)
      annotation.content = content
      annotation.save!
    else
      find_by(user:, territory:)&.destroy!
    end
  end
end
