class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  include Authorizable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,  :async

  belongs_to :organisation, optional: true
  has_many :rdvs, dependent: :destroy
  has_and_belongs_to_many :rdvs

  validates :last_name, :first_name, :email, presence: true
  validates :email, format: { with: Devise.email_regexp }, uniqueness: { case_sensitive: false, scope: :organisation }

  include PgSearch::Model
  pg_search_scope :search_by_name, against: [:first_name, :last_name],
                  using: { tsearch: { prefix: true } }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    full_name.split.first(2).map(&:first).join.upcase
  end

  def age
    years = age_in_years
    return "#{years} ans" if years >= 2

    months = age_in_months
    return "#{months} mois" if months.positive?

    "#{age_in_days.to_i} jours"
  end

  def age_in_years
    today = Time.zone.now.to_date
    years = today.year - birth_date.year
    if today.month > birth_date.month || (today.month == birth_date.month && today.day >= birth_date.day)
      years
    else
      years - 1
    end
  end

  def age_in_months
    today = Time.zone.now.to_date
    (today.year - birth_date.year) * 12 + today.month - birth_date.month - (today.day >= birth_date.day ? 0 : 1)
  end

  def age_in_days
    Time.zone.now.to_date - birth_date
  end
end
