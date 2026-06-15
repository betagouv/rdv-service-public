class Rdv < ApplicationRecord
  # Mixins
  has_paper_trail(only: %w[user_ids agent_ids status starts_at ends_at lieu_id context participations], meta: { virtual_attributes: :virtual_attributes_for_paper_trail })
  include WebhookDeliverable
  include Rdv::AddressConcern
  include Rdv::AuthoredConcern
  include Rdv::VisioConcern
  include Rdv::Updatable
  include Rdv::UsingWaitingRoom
  include Rdv::HardcodedAttributeNamesConcern
  include Rdv::TimezoneConcern
  include IcsPayloads::Rdv
  include Ants::AppointmentSerializerAndListener
  include CreatedByConcern

  # Attributes
  auto_strip_attributes :name
  enum status: { unknown: "unknown", seen: "seen", excused: "excused", revoked: "revoked", noshow: "noshow" }
  enum created_by: { user: "user", agent: "agent", file_attente: "file_attente" }

  # Commentaire pour les status explications
  # unknown : "A renseigner" ou "A venir" (si le rdv est passé ou pas)
  # seen : Présent au rdv
  # noshow : Lapin
  # excused : Annulé à l'initiative de l'usager
  # revoked : Annulé à l'initiative du service

  MIN_DELAY_FOR_CANCEL = 4.hours
  NOT_CANCELLED_STATUSES = %w[unknown seen noshow].freeze
  CANCELLED_STATUSES = %w[excused revoked].freeze
  COLLECTIVE_RDV_STATUSES = %w[unknown seen revoked].freeze
  RDV_STATUSES_TO_NOTIFY = %w[unknown excused revoked].freeze

  # Relations
  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true
  has_many :file_attentes, dependent: :destroy
  has_many :agents_rdvs, inverse_of: :rdv, dependent: :destroy
  # https://stackoverflow.com/questions/30629680/rails-isnt-running-destroy-callbacks-for-has-many-through-join-model/30629704
  # https://github.com/rails/rails/issues/7618
  has_many :participations, validate: false, inverse_of: :rdv, dependent: :destroy, class_name: "Participation"
  has_many :receipts, dependent: :nullify
  has_many :external_references, as: :item, dependent: :destroy
  accepts_nested_attributes_for :participations, allow_destroy: true
  accepts_nested_attributes_for :lieu

  ACCEPTED_NESTED_LIEU_ATTRIBUTES = %w[name address latitude longitude].freeze

  def nested_lieu_attributes
    lieu&.attributes&.slice(*ACCEPTED_NESTED_LIEU_ATTRIBUTES)
  end

  # Through relations
  has_many :agents, through: :agents_rdvs, dependent: :destroy
  has_many :users, through: :participations, validate: false
  has_many :webhook_endpoints, through: :organisation
  has_one :territory, through: :organisation
  has_one :rdv_plan, dependent: :destroy

  # Delegates
  delegate :home?, :phone?, :public_office?, :visio?, :bookable_by_everyone?, :bookable_by_everyone_or_bookable_by_invited_users?, :service_social?, :follow_up?, :service, :collectif?, :collectif, :individuel?, :requires_ants_predemande_number?, :service_name, :service_short_name, to: :motif

  # Validations
  validates :starts_at, :ends_at, :agents, :status, presence: true
  validate :lieu_is_not_disabled_if_needed
  validates :starts_at, realistic_date: true
  validate :duration_is_plausible
  validates :max_participants_count, numericality: { greater_than: 0, allow_nil: true }
  validates :participations, presence: true, unless: :collectif?
  validate :validate_motif_organisation

  # Hooks
  after_save :associate_users_with_organisation
  after_commit :update_agents_unknown_past_rdv_count, if: -> { past? }
  before_validation { self.uuid ||= SecureRandom.uuid }
  before_create :set_created_by_for_participations
  # voir Outlook::EventSerializerAndListener pour d'autres callbacks
  # voir Ants::AppointmentSerializerAndListener pour d'autres callbacks
  after_save do
    # On fait un where plutôt que d'utiliser directement l'association pour éviter des effets de bords sur les objets AR.
    AgentsRdv.where(rdv_id: id).update_all(
      calculator_rdv_starts_at: starts_at,
      calculator_rdv_ends_at: ends_at + minutes_after_rdv.minutes,
      calculator_rdv_not_cancelled_and_in_the_future: not_cancelled_and_in_the_future?
    )
  end

  before_destroy(prepend: true) { @agent_ids_before_change = agent_ids }
  before_save { @agent_ids_before_change = agent_ids }

  after_commit do
    refresh_periods = [[starts_at, ends_at]]
    refresh_periods.push([starts_at_previously_was, ends_at_previously_was]) if starts_at_previously_changed? || ends_at_previously_changed?
    (agent_ids_from_db + (@agent_ids_before_change || [])).uniq.each do |agent_id|
      AgendaChannel.broadcast_to(agent_id, model: "Rdv", refresh_periods:)
    end
  end

  # Scopes
  scope :not_cancelled, -> { where(status: NOT_CANCELLED_STATUSES) }
  scope :past, -> { where("starts_at < ?", Time.zone.now) }
  scope :future, -> { where("starts_at > ?", Time.zone.now) }
  scope :starts_after, ->(time) { where("starts_at >= ?", time) }
  scope :starts_before, ->(time) { where("starts_at <= ?", time) }
  scope :on_day, ->(day) { where(starts_at: day.all_day) }
  scope :day_after_tomorrow, -> { on_day(Time.zone.tomorrow + 1.day) }
  scope :f
end