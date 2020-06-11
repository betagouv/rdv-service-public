class Rdv < ApplicationRecord
  include WebhookDeliverable

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

  has_many :webhook_endpoints, through: :organisation

  enum status: { unknown: 0, waiting: 1, seen: 2, excused: 3, notexcused: 4 }
  enum created_by: { agent: 0, user: 1, file_attente: 2 }, _prefix: :created_by

  delegate :home?, :phone?, :public_office?, :reservable_online?, to: :motif

  validates :users, :organisation, :motif, :starts_at, :duration_in_min, :agents, presence: true

  scope :active, -> { where(cancelled_at: nil) }
  scope :past, -> { where('starts_at < ?', Time.zone.now) }
  scope :future, -> { where('starts_at > ?', Time.zone.now) }
  scope :tomorrow, -> { where(starts_at: DateTime.tomorrow...DateTime.tomorrow + 1.day) }
  scope :day_after_tomorrow, -> { where(starts_at: DateTime.tomorrow + 1.day...DateTime.tomorrow + 2.day) }
  scope :user_with_relatives, ->(responsible_id) { joins(:users).includes(:rdvs_users, :users).where('users.id IN (?)', [responsible_id, User.find(responsible_id).relatives.pluck(:id)].flatten) }
  scope :status, lambda { |status|
    if status == 'unknown_past'
      past.where(status: ['unknown', 'waiting'])
    elsif status == 'unknown_future'
      future.where(status: ['unknown', 'waiting'])
    else
      where(status: status)
    end
  }
  scope :default_stats_period, -> { where(created_at: Stat::DEFAULT_RANGE) }

  after_commit :reload_uuid, on: :create

  after_create :notify_rdv_created
  after_save :associate_users_with_organisation
  after_update :notify_rdv_updated, if: -> { saved_change_to_starts_at? }

  def agenda_path_for_agent(agent)
    agent_for_agenda = agents.include?(agent) ? agent : agents.first

    Rails.application.routes.url_helpers.organisation_agent_path(organisation, agent_for_agenda, date: starts_at.to_date)
  end

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def past?
    ends_at < Time.zone.now
  end

  def cancelled?
    cancelled_at.present?
  end

  def cancel
    update(cancelled_at: Time.zone.now, status: :excused)
  end

  def cancellable?
    !cancelled? && starts_at > 4.hours.from_now
  end

  def to_query
    {
      motif_id: motif&.id,
      lieu_id: lieu_id,
      duration_in_min: duration_in_min,
      starts_at: starts_at&.to_s,
      user_ids: users&.map(&:id),
      agent_ids: agents&.map(&:id),
      notes: notes,
    }
  end

  def available_to_file_attente?
    !cancelled? && starts_at > 7.days.from_now && !home?
  end

  def creneaux_available(date_range)
    lieu.present? ? CreneauxBuilderService.perform_with(motif.name, lieu, date_range) : []
  end

  def notify_rdv_created
    Notifications::Rdv::RdvCreatedService.perform_with(self)
  end

  def notify_rdv_updated
    Notifications::Rdv::RdvUpdatedService.perform_with(self)
  end

  def address
    return location if location.present? && lieu_id.nil?

    user = user_for_home_rdv
    if home? && user.present?
      user.address.to_s
    elsif public_office? && lieu.present?
      lieu.address
    else
      ""
    end
  end

  def complete_address
    return location if location.present? && lieu_id.nil?

    user = user_for_home_rdv
    if home? && user.present?
      "Adresse de #{user.full_name} - #{user.responsible_address}"
    elsif public_office? && lieu.present?
      lieu.full_name
    else
      ""
    end
  end

  def user_for_home_rdv
    responsibles = users.where.not(responsible_id: [nil])
    [responsibles, users].flatten.select(&:address).first
  end

  private

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
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? 'uuid'
  end
end
