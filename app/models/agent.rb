class Agent < ApplicationRecord
  has_paper_trail
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  include DeviseInvitable::Inviter
  include FullNameConcern
  include AccountNormalizerConcern

  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable, :confirmable, :async, validate_on_invite: true

  belongs_to :service
  has_many :lieux, through: :organisation
  has_many :motifs, through: :service
  has_many :plage_ouvertures, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy
  has_many :rdvs, dependent: :destroy, through: :agents_rdvs
  has_and_belongs_to_many :organisations, -> { distinct }
  has_and_belongs_to_many :users

  enum role: { user: 0, admin: 1 }

  validates :email, :role, presence: true
  validates :last_name, :first_name, presence: true, on: :update, if: :accepted_or_not_invited?

  scope :complete, -> { where.not(first_name: nil).where.not(last_name: nil) }
  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql('LOWER(last_name)')) }
  scope :secretariat, -> { joins(:service).where(services: { name: 'Secrétariat'.freeze }) }
  scope :can_perform_motif, lambda { |motif|
    motif.for_secretariat ? joins(:service).where(service: motif.service).or(secretariat) : where(service: motif.service)
  }

  before_save :normalize_account

  def full_name_and_service
    service.present? ? "#{full_name} (#{service.short_name})" : full_name
  end

  def complete?
    first_name.present? && last_name.present?
  end

  ## Soft Delete for Devise
  def soft_delete(organisation = nil)
    organisations.delete(organisation) && return if organisation.present? && organisations.count > 1
    rdvs.empty? ? destroy : update_attribute(:deleted_at, Time.zone.now)
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def inactive_message
    !deleted_at ? super : :deleted_account
  end

  def can_access_others_planning?
    admin? || service.secretariat?
  end

  def add_organisation(organisation)
    errors.add(:email, 'existe déjà dans cette organisation') && return if organisation_ids.include?(organisation.id)
    organisations << organisation
  end
end
