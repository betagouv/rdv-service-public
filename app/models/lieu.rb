class Lieu < ApplicationRecord
  belongs_to :organisation

  validates :name, :address, :telephone, :horaires, presence: true

  def full_name
    "#{name} (#{address})"
  end
end
