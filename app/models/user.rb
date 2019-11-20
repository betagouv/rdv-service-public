class User < ApplicationRecord
  include PgSearch::Model

  attr_accessor :created_or_updated_by_agent

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  has_and_belongs_to_many :organisations, -> { distinct }, after_add: :add_organisation_to_children, after_remove: :remove_organisation_to_children
  has_and_belongs_to_many :rdvs
  belongs_to :parent, foreign_key: "parent_id", class_name: "User", optional: true
  has_many :children, foreign_key: "parent_id", class_name: "User"

  enum caisse_affiliation: { aucune: 0, caf: 1, msa: 2 }
  enum family_situation: { single: 0, in_a_relationship: 1, divorced: 2 }
  enum logement: { sdf: 0, heberge: 1, locataire: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4 }

  validates :last_name, :first_name, presence: true
  validates :number_of_children, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :birth_date_validity

  pg_search_scope :search_by_name_or_email, against: [:first_name, :last_name, :email],
                  using: { tsearch: { prefix: true } }

  before_save :set_email_to_null_if_blank
  before_save :set_organisation_ids_from_parent, if: :parent_id_changed?

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

  def add_organisation(organisation)
    organisations << organisation if organisation_ids.exclude?(organisation.id)
  end

  def soft_delete
    delete
  end

  def available_users_for_rdv
    User.where(parent_id: id).or(User.where(id: id)).order('parent_id DESC NULLS FIRST', first_name: :asc)
  end

  def child?
    parent_id.present?
  end

  protected

  def password_required?
    return false if created_or_updated_by_agent || child?

    super
  end

  def email_required?
    return false if created_or_updated_by_agent || child?

    super
  end

  private

  def add_organisation_to_children(organisation)
    children.each { |child| child.add_organisation(organisation) }
  end

  def remove_organisation_to_children(organisation)
    children.each { |child| child.organisations.delete(organisation) }
  end

  def set_organisation_ids_from_parent
    self.organisation_ids = parent.organisation_ids if parent
  end

  def set_email_to_null_if_blank
    self.email = nil if email.blank?
  end

  def birth_date_validity
    return unless birth_date.present?
    if birth_date > Date.today || birth_date < 120.years.ago
      errors.add(:birth_date, "est invalide")
    end
  end

end
