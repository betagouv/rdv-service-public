class Organisation < ApplicationRecord
  has_paper_trail
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :rdvs, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :zones
  has_and_belongs_to_many :agents, -> { distinct }
  has_and_belongs_to_many :users, -> { distinct }

  validates :name, presence: true, uniqueness: true
  validates :departement, presence: true, length: { is: 2 }
  validates :phone_number, phone: { allow_blank: true }
  validates(
    :human_id,
    format: {
      with: /\A[a-z0-9_\-]{3,99}\z/,
      message: :human_id_error,
      if: -> { human_id.present? }
    }
  )

  after_create :notify_admin_organisation_created

  accepts_nested_attributes_for :agents

  def self.in_zone_or_departement(zone, departement)
    zone ? [zone.organisation] : Organisation.where(departement: departement)
  end

  def notify_admin_organisation_created
    return unless agents.present?

    Admins::OrganisationMailer.organisation_created(agents.first).deliver_later
  end

  def recent?
    1.week.ago < created_at
  end
end
