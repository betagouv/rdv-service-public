class Motif < ApplicationRecord
  # Mixins
  has_paper_trail
  include WebhookDeliverable
  include PgSearch::Model

  pg_search_scope(:search_by_text,
                  against: :name,
                  using: { tsearch: { prefix: true } },
                  ignoring: :accents) # Motif text search is not indexed, but at least we can use PG unaccent. See #1772 and #1833

  # Attributes
  auto_strip_attributes :name, :color

  NAME_SLUG_REGEXP = /[^0-9a-z]+/

  # TODO: make it an enum
  VISIBLE_AND_NOTIFIED = "visible_and_notified".freeze
  VISIBLE_AND_NOT_NOTIFIED = "visible_and_not_notified".freeze
  INVISIBLE = "invisible".freeze
  VISIBILITY_TYPES = [VISIBLE_AND_NOTIFIED, VISIBLE_AND_NOT_NOTIFIED, INVISIBLE].freeze

  # TODO: make it an enum
  SECTORISATION_LEVEL_AGENT = "agent".freeze
  SECTORISATION_LEVEL_ORGANISATION = "organisation".freeze
  SECTORISATION_LEVEL_DEPARTEMENT = "departement".freeze
  SECTORISATION_TYPES = [SECTORISATION_LEVEL_AGENT, SECTORISATION_LEVEL_ORGANISATION, SECTORISATION_LEVEL_DEPARTEMENT].freeze

  enum :location_type, { public_office: "public_office", phone: "phone", home: "home", visio: "visio" }
  enum :bookable_by, {
    agents: "agents",
    agents_and_prescripteurs: "agents_and_prescripteurs",
    agents_and_prescripteurs_and_invited_users: "agents_and_prescripteurs_and_invited_users",
    everyone: "everyone",
  }

  # Relations
  belongs_to :organisation
  belongs_to :service
  belongs_to :motif_category, optional: true
  has_many :rdvs, dependent: :restrict_with_exception
  has_many :motifs_plage_ouvertures, dependent: :delete_all

  # Through relations
  has_many :webhook_endpoints, through: :organisation
  has_many :plage_ouvertures, -> { distinct }, through: :motifs_plage_ouvertures
  has_many :lieux_through_po, through: :plage_ouvertures, source: :lieu
  has_many :lieux_through_rdvs, through: :rdvs, source: :lieu

  def lieux
    collectif? ? lieux_through_rdvs : lieux_through_po
  end

  # Delegates
  delegate :service_social?, to: :service
  delegate :name, to: :service, prefix: true

  # Validation
  validates :visibility_type, inclusion: { in: VISIBILITY_TYPES }
  validates :sectorisation_level, inclusion: { in: SECTORISATION_TYPES }
  validates :name, presence: true, uniqueness: { scope: %i[organisation location_type service],
                                                 conditions: -> { where(deleted_at: nil) }, }

  validates :color, :default_duration_in_min, :min_public_booking_delay, :max_public_booking_delay, presence: true
  validates :min_public_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validates :max_public_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validate :booking_delay_validation
  validate :not_associated_with_secretariat
  validates :color, css_hex_color: true
  validate :not_at_home_if_collectif
  validate :cant_change_once_rdvs_exist
  validate :cant_be_for_secretariat_and_follow_up

  # Scopes
  scope :active, lambda { |active = true|
    active ? where(deleted_at: nil) : where.not(deleted_at: nil)
  }
  scope :bookable_by_everyone, -> { where(bookable_by: %i[everyone]) }
  scope :bookable_by_everyone_or_bookable_by_invited_users, -> { where(bookable_by: %i[everyone agents_and_prescripteurs_and_invited_users]) }
  scope :bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users, -> { where(bookable_by: %i[everyone agents_and_prescripteurs agents_and_prescripteurs_and_invited_users]) }
  scope :not_bookable_by_everyone_or_not_bookable_by_invited_users, -> { where.not(bookable_by: %i[everyone agents_and_prescripteurs_and_invited_users]) }
  scope :by_phone, -> { Motif.phone } # default scope created by enum
  scope :for_secretariat, -> { where(for_secretariat: true) }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(motifs.name))")) }
  scope :available_for_booking, lambda {
    where_id_in_subqueries(
      [
        individuel.active.bookable_by_everyone_or_bookable_by_invited_users.joins(:organisation, :plage_ouvertures).select(:id),
        Rdv.collectif_and_available_for_reservation.select(:motif_id),
      ]
    )
  }
  scope :available_motifs_for_organisation_and_agent, lambda { |organisation, agent|
    available_motifs = if agent.admin_in_organisation?(organisation)
                         all
                       else
                         where(service: agent.services)
                       end

    if agent.secretaire?
      available_motifs = available_motifs.or(for_secretariat)
    end
    available_motifs.where(organisation_id: organisation.id).active.ordered_by_name
  }
  # This should match the implementation of #name_with_location_type
  scope :search_by_name_with_location_type, lambda { |name_with_location_type|
    slug_name, location_type = Motif.location_types.keys.map do |location_type|
      match_data = name_with_location_type&.match(/(.*)-#{location_type}$/)
      match_data ? [match_data[1], location_type] : nil
    end.compact.first
    where(%{REGEXP_REPLACE(LOWER(UNACCENT(motifs.name)), ?, '_', 'g') = ?}, NAME_SLUG_REGEXP.source, slug_name)
      .where(location_type: location_type)
  }
  scope :sectorized, -> { where(sectorisation_level: [SECTORISATION_LEVEL_ORGANISATION, SECTORISATION_LEVEL_AGENT]) }
  scope :sectorisation_level_departement, -> { where(sectorisation_level: SECTORISATION_LEVEL_DEPARTEMENT) }
  scope :sectorisation_level_organisation, -> { where(sectorisation_level: SECTORISATION_LEVEL_ORGANISATION) }
  scope :sectorisation_level_agent, -> { where(sectorisation_level: SECTORISATION_LEVEL_AGENT) }
  scope :in_departement, lambda { |departement_number|
    joins(organisation: :territory)
      .where(organisations: { territories: { departement_number: departement_number } })
  }
  scope :visible, -> { where(visibility_type: [Motif::VISIBLE_AND_NOTIFIED, Motif::VISIBLE_AND_NOT_NOTIFIED]) }
  scope :collectif, -> { where(collectif: true) }
  scope :individuel, -> { where(collectif: false) }
  scope :with_motif_category_short_name, lambda { |motif_category_short_name|
    joins(:motif_category)
      .where(motif_category: { short_name: motif_category_short_name })
  }
  scope :requires_ants_predemande_number, -> { joins(:motif_category).merge(MotifCategory.requires_ants_predemande_number) }

  ## -

  def to_s
    name
  end

  def soft_delete
    rdvs.any? ? update_attribute(:deleted_at, Time.zone.now) : destroy
  end

  def authorized_agents
    Agent
      .joins(:organisations)
      .where(organisations: { id: organisation.id })
      .includes(:services)
      .complete
      .active
      .ordered_by_last_name
  end

  def visible_and_notified?
    visibility_type == VISIBLE_AND_NOTIFIED
  end

  # This should match the implementation of .search_by_name_with_location_type
  def name_with_location_type
    "#{I18n.transliterate(name).downcase.gsub(NAME_SLUG_REGEXP, '_')}-#{location_type}"
  end

  def sectorisation_level_agent?
    sectorisation_level == SECTORISATION_LEVEL_AGENT
  end

  def sectorisation_level_organisation?
    sectorisation_level == SECTORISATION_LEVEL_ORGANISATION
  end

  def sectorisation_level_departement?
    sectorisation_level == SECTORISATION_LEVEL_DEPARTEMENT
  end

  def cancellation_warning
    custom_cancel_warning_message.presence || Motif.human_attribute_name("default_cancel_warning_message")
  end

  def start_booking_delay
    Time.zone.now + min_public_booking_delay.seconds
  end

  def end_booking_delay
    Time.zone.now + max_public_booking_delay.seconds
  end

  def booking_delay_range
    start_booking_delay..end_booking_delay
  end

  def individuel?
    !collectif?
  end

  def requires_lieu?
    public_office?
  end

  def self.with_availability_for_lieux(lieu_ids)
    individual_motif_ids = individuel.joins(:plage_ouvertures).where(plage_ouvertures: { lieu_id: lieu_ids }).select(:id)
    collective_motif_ids = Rdv.collectif_and_available_for_reservation
      .where(lieu_id: lieu_ids, motif: collectif).select(:motif_id)

    where_id_in_subqueries([individual_motif_ids, collective_motif_ids])
  end

  def self.with_availability_for_agents(agent_ids)
    individual_motif_ids = individuel.joins(:plage_ouvertures).where(plage_ouvertures: { agent_id: agent_ids }).select(:id)
    collective_motif_ids = Rdv.collectif_and_available_for_reservation
      .where(motif: collectif).joins(:agents).where(agents: { id: agent_ids }).select(:motif_id)

    where_id_in_subqueries([individual_motif_ids, collective_motif_ids])
  end

  def bookable_publicly
    # bookable_publicly has been renamed to bookable_by_everyone_or_bookable_by_invited_users. Keep this for API compatibility
    bookable_by_everyone_or_bookable_by_invited_users?
  end

  def bookable_by_everyone_or_bookable_by_invited_users?
    bookable_by_everyone? || bookable_by_invited_users?
  end

  def bookable_by_everyone?
    bookable_by == "everyone"
  end

  def bookable_by_agents_and_prescripteurs?
    bookable_by == "agents_and_prescripteurs"
  end

  def bookable_by_invited_users?
    bookable_by == "agents_and_prescripteurs_and_invited_users"
  end

  def bookable_outside_of_organisation?
    bookable_by != "agents"
  end

  def requires_ants_predemande_number?
    motif_category&.requires_ants_predemande_number?
  end

  attr_accessor :duplicated_from_motif_id

  private

  def booking_delay_validation
    return if min_public_booking_delay.zero? && max_public_booking_delay.zero?

    errors.add(:max_public_booking_delay, "doit être supérieur au délai de réservation minimum") if max_public_booking_delay <= min_public_booking_delay
  end

  def not_associated_with_secretariat
    return if service_id.nil?

    errors.add(:service_id, "ne peut être le secrétariat") if service.secretariat?
  end

  def not_at_home_if_collectif
    return unless collectif? && !public_office?

    errors.add(:base, :not_at_home_if_collectif)
  end

  def cant_change_once_rdvs_exist
    return unless rdvs.exists?

    errors.add(:collectif, :cant_change_because_already_used) if attribute_changed?(:collectif)
    errors.add(:location_type, :cant_change_because_already_used) if attribute_changed?(:location_type)
  end

  def cant_be_for_secretariat_and_follow_up
    if for_secretariat && follow_up
      errors.add(:for_secretariat, :cant_be_enabled_if_follow_up)
    end
  end
end
