class User < ApplicationRecord
  belongs_to :organisation, optional: true
  has_many :rdvs, dependent: :destroy

  validates :last_name, :first_name, presence: true
  validates :email, format: { with: Devise.email_regexp }, uniqueness: { case_sensitive: false, scope: :organisation }
  include PgSearch
  pg_search_scope :search_by_name, against: [:first_name, :last_name],
                  using: { tsearch: {prefix: true} }

  def full_name
    "#{first_name} #{last_name}"
  end

  def age
    now = Time.zone.now.to_date
    age = now.year - birth_date.year
    if now.month > birth_date.month || (now.month == birth_date.month && now.day >= birth_date.day)
      age
    else
      age - 1
    end
  end
end
