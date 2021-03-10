class Organisation < ApplicationRecord
  has_paper_trail
  belongs_to :territory
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :rdvs, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :sector_attributions, dependent: :destroy
  has_many :sectors, through: :sector_attributions
  has_many :plage_ouvertures, dependent: :destroy
  has_many :agent_roles, dependent: :delete_all # skips last admin validation
  has_many :agents, through: :agent_roles

  has_many :user_profiles
  has_many :users, through: :user_profiles

  validates :name, presence: true, uniqueness: { scope: :territory }
  validates :phone_number, phone: { allow_blank: true }
  validates(
    :human_id,
    format: {
      with: /\A[a-z0-9_\-]{3,99}\z/,
      message: :human_id_error,
      if: -> { human_id.present? }
    }
  )
  validates :human_id, uniqueness: { scope: :territory }, if: -> { human_id.present? }

  after_create :notify_admin_organisation_created

  accepts_nested_attributes_for :agent_roles
  accepts_nested_attributes_for :territory

  scope :attributed_to_sectors, lambda { |sectors|
    where(
      id: SectorAttribution
        .level_organisation
        .where(sector_id: sectors.pluck(:id))
        .pluck(:organisation_id)
    )
  }
  scope :order_by_name, -> { order(Arel.sql("LOWER(name)")) }
  scope :contactable, lambda {
    where.not(phone_number: ["", nil])
      .or(where.not(website: ["", nil]))
      .or(where.not(email: ["", nil]))
  }
  scope :with_upcoming_rdvs, lambda {
    where(id: Rdv.future.distinct.pluck(:organisation_id))
  }

  def notify_admin_organisation_created
    return unless agents.present?

    Admins::OrganisationMailer.organisation_created(agents.first, self).deliver_later
  end

  def recent?
    1.week.ago < created_at
  end
end
