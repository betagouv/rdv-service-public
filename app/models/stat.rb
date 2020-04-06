class Stat
  include ActiveModel::Model
  attr_accessor :users, :rdvs

  DEFAULT_RANGE = (Date.strptime('01/02/2020', '%d/%m/%Y').beginning_of_day..Time.zone.now.end_of_day).freeze

  def rdvs_for_default_range
    rdvs.where(created_at: DEFAULT_RANGE)
  end

  def users_for_default_range
    users.active.where(created_at: DEFAULT_RANGE)
  end

  def rdvs_group_by_week
    rdvs.group(:created_by).group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: '%d/%m/%Y').count
  end

  def rdvs_group_by_departement
    rdvs.joins(:organisation).group('organisations.departement').group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: '%d/%m/%Y').count
  end

  def rdvs_group_by_service
    rdvs.joins(motif: :service).group('services.name').group_by_week('rdvs.created_at', range: DEFAULT_RANGE, format: '%d/%m/%Y').count
  end

  def users_group_by_week
    users.active.group_by_week('users.created_at', range: DEFAULT_RANGE, format: '%d/%m/%Y').count
  end

  def rdvs_group_by_week_fr
    rdvs_group_by_week.transform_keys { |key| key[0] == 'agent' ? ["agent (#{rdvs_for_default_range.created_by_agent.count})", key[1]] : ["usager (#{rdvs_for_default_range.created_by_user.count})", key[1]] }
  end
end
