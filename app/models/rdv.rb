class Rdv < ApplicationRecord
  include WebhookDeliverable
  include Rdv::NotifiableConcern

  has_paper_trail(
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )
  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true
  has_many :file_attentes, dependent: :destroy
  has_many :agents_rdvs, inverse_of: :rdv, dependent: :destroy
  has_many :agents, through: :agents_rdvs
  has_many :rdvs_users, validate: false, inverse_of: :rdv, dependent: :destroy
  has_many :users, through: :rdvs_users, validate: false
  has_many :events, class_name: "RdvEvent", dependent: :destroy

  has_many :webhook_endpoints, through: :organisation

  enum status: { unknown: 0, waiting: 1, seen: 2, excused: 3, notexcused: 4 }
  enum created_by: { agent: 0, user: 1, file_attente: 2 }, _prefix: :created_by

  delegate :home?, :phone?, :public_office?, :reservable_online?, :service_social?, :service, to: :motif

  validates :users, :organisation, :motif, :starts_at, :duration_in_min, :agents, presence: true
  validates :lieu, presence: true, if: :public_office?

  scope :not_cancelled, -> { where(cancelled_at: nil) }
  scope :cancelled, -> { where.not(cancelled_at: nil) }
  scope :past, -> { where("starts_at < ?", Time.zone.now) }
  scope :future, -> { where("starts_at > ?", Time.zone.now) }
  scope :tomorrow, -> { where(starts_at: DateTime.tomorrow...DateTime.tomorrow + 1.day) }
  scope :day_after_tomorrow, -> { where(starts_at: DateTime.tomorrow + 1.day...DateTime.tomorrow + 2.day) }
  scope :for_today, -> { where(starts_at: Time.zone.now.beginning_of_day...Time.zone.now.end_of_day) }
  scope :user_with_relatives, ->(responsible_id) { joins(:users).includes(:rdvs_users, :users).where("users.id IN (?)", [responsible_id, User.find(responsible_id).relatives.pluck(:id)].flatten) }
  scope :status, lambda { |status|
    if status == "unknown_past"
      past.where(status: ["unknown", "waiting"])
    elsif status == "unknown_future"
      future.where(status: ["unknown", "waiting"])
    else
      where(status: status)
    end
  }
  scope :default_stats_period, -> { where(created_at: Stat.default_date_range) }
  scope :with_agent, ->(agent) { joins(:agents).where(agents: { id: agent.id }) }
  scope :with_user, ->(user) { joins(:rdvs_users).where(rdvs_users: { user_id: user.id }) }
  scope :with_user_in, ->(users) { joins(:rdvs_users).where(rdvs_users: { user_id: users.pluck(:id) }).distinct }
  scope :with_lieu, ->(lieu) { joins(:lieu).where(lieux: { id: lieu.id }) }
  scope :visible, -> { joins(:motif).where(motifs: { visibility_type: [Motif::VISIBLE_AND_NOTIFIED, Motif::VISIBLE_AND_NOT_NOTIFIED] }) }

  after_commit :reload_uuid, on: :create
  after_save :associate_users_with_organisation

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def past?
    ends_at < Time.zone.now
  end

  def in_the_future?
    starts_at > Time.zone.now
  end

  def temporal_status
    return "unknown_future" if unknown? && in_the_future?
    return "unknown_past" if unknown? && !in_the_future?

    status
  end

  def possible_temporal_statuses
    if in_the_future?
      ["unknown_future", starts_at.to_date.today? ? "waiting" : nil, "excused"].compact
    else
      %w[unknown_past seen notexcused excused]
    end
  end

  def cancelled?
    cancelled_at.present?
  end

  def cancellable?
    !cancelled? && starts_at > 4.hours.from_now
  end

  def available_to_file_attente?
    !cancelled? && starts_at > 7.days.from_now && !home?
  end

  def creneaux_available(date_range)
    lieu.present? ? CreneauxBuilderService.perform_with(motif.name, lieu, date_range) : []
  end

  def address
    return location if location_without_lieu?
    return user_for_home_rdv.address.to_s if home? && user_for_home_rdv.present?
    return lieu.address if public_office? && lieu.present?

    ""
  end

  def address_complete
    return location if location_without_lieu?
    return "Adresse de #{user_for_home_rdv.full_name} - #{user_for_home_rdv.responsible_address}" if home? && user_for_home_rdv.present?
    return lieu.full_name if public_office? && lieu.present?

    ""
  end

  def address_complete_without_personnal_details
    return "Par téléphone" if phone?
    return "À domicile" if home?

    address_complete
  end

  def user_for_home_rdv
    responsibles = users.where.not(responsible_id: [nil])
    [responsibles, users].flatten.select(&:address).first || users.first
  end

  def overlapping_plages_ouvertures
    return [] if starts_at.blank? || duration_in_min.blank? || lieu.blank? || past?

    @overlapping_plages_ouvertures ||= PlageOuverture.where(agent: agent_ids).where.not(lieu: lieu).overlapping_with_time_slot(to_time_slot)
  end

  def overlapping_plages_ouvertures?
    overlapping_plages_ouvertures.any?
  end

  def to_time_slot
    TimeSlot.new(starts_at, ends_at)
  end

  private

  def location_without_lieu?
    location.present? && lieu_id.nil?
  end

  def virtual_attributes_for_paper_trail
    { user_ids: users&.pluck(:id), agent_ids: agents&.pluck(:id) }
  end

  def associate_users_with_organisation
    users.each do |u|
      u.add_organisation(organisation)
    end
  end

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? "uuid"
  end
end
