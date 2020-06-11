class Stat
  include ActiveModel::Model
  attr_accessor :agents, :organisations, :users, :rdvs

  DEFAULT_RANGE = (Date.strptime('01/02/2020', '%d/%m/%Y').beginning_of_day..Time.zone.now.end_of_day).freeze
  DEFAULT_FORMAT = '%d/%m/%Y'.freeze

  def rdvs_for_default_range
    rdvs.where(created_at: DEFAULT_RANGE)
  end

  def users_for_default_range
    users.active.where(created_at: DEFAULT_RANGE)
  end

  def users_group_by_week
    users.active.group_by_week('users.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count
  end

  def organisations_for_default_range
    organisations.where(created_at: DEFAULT_RANGE)
  end

  def organisations_group_by_week
    organisations.group_by_week('organisations.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count
  end

  def agents_for_default_range
    agents.active.where(created_at: DEFAULT_RANGE)
  end

  def agents_group_by_week
    agents.active.group_by_week('agents.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week
    rdvs.group(:created_by).group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_type
    rdvs.joins(:motif).group('motifs.location_type').group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count.transform_keys { |key| [I18n.t(Motif.location_types.invert[key[0]]), key[1]] }
  end

  def rdvs_group_by_departement
    rdvs.joins(:organisation).group('organisations.departement').group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_service
    rdvs.joins(motif: :service).group('services.name').group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week_fr
    new_keys = {
      agent: "Agent (#{rdvs_for_default_range.created_by_agent.count})",
      user: "Usager (#{rdvs_for_default_range.created_by_user.count})",
      file_attente: "File d'attente (#{rdvs_for_default_range.created_by_file_attente.count})",
    }
    rdvs_group_by_week.transform_keys { |key| [new_keys[key[0].to_sym], key[1]] }
  end
end
