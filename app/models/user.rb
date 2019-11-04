class User < ApplicationRecord
  include Authorizable
  include PgSearch::Model

  attr_accessor :created_or_updated_by_agent

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  has_and_belongs_to_many :organisations, -> { distinct }
  has_and_belongs_to_many :rdvs

  enum caisse_affiliation: { aucune: 0, caf: 1, msa: 2 }
  enum family_situation: { single: 0, in_a_relationship: 1, divorced: 2 }
  enum logement: { sdf: 0, heberge: 1, locataire: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4 }

  validates :last_name, :first_name, presence: true
  validates :number_of_children, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  pg_search_scope :search_by_name, against: [:first_name, :last_name],
                  using: { tsearch: { prefix: true } }

  before_save :set_email_to_null_if_blank

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

  protected

  def password_required?
    return false if created_or_updated_by_agent

    super
  end

  def email_required?
    return false if created_or_updated_by_agent

    super
  end

  private

  def set_email_to_null_if_blank
    self.email = nil if email.blank?
  end
end
