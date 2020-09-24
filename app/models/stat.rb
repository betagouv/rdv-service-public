class Stat
  include ActiveModel::Model
  attr_accessor :agents, :organisations, :users, :rdvs

  DEFAULT_FORMAT = "%d/%m/%Y".freeze

  def rdvs_for_default_range
    rdvs.where(created_at: default_date_range)
  end

  def users_for_default_range
    users.active.where(created_at: default_date_range)
  end

  def users_group_by_week
    users.active.group_by_week("users.created_at", range: default_date_range, format: DEFAULT_FORMAT).count
  end

  def organisations_for_default_range
    organisations.where(created_at: default_date_range)
  end

  def organisations_group_by_week
    organisations.group_by_week("organisations.created_at", range: default_date_range, format: DEFAULT_FORMAT).count
  end

  def agents_for_default_range
    agents.active.where(created_at: default_date_range)
  end

  def agents_group_by_week
    agents.active.group_by_week("agents.created_at", range: default_date_range, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week
    rdvs.group(:created_by).group_by_week("rdvs.created_at", range: default_date_range, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_type
    rdvs.joins(:motif).group("motifs.location_type").group_by_week("rdvs.created_at", range: default_date_range, format: DEFAULT_FORMAT).count.transform_keys { |key| [I18n.t(Motif.location_types.invert[key[0]]), key[1]] }
  end

  def rdvs_group_by_departement
    rdvs.joins(:organisation).group("organisations.departement").group_by_week("rdvs.created_at", range: default_date_range, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_service
    rdvs.joins(motif: :service).group("services.name").group_by_week("rdvs.created_at", range: default_date_range, format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week_fr
    new_keys = {
      agent: "Agent (#{rdvs_for_default_range.created_by_agent.count})",
      user: "Usager (#{rdvs_for_default_range.created_by_user.count})",
      file_attente: "File d'attente (#{rdvs_for_default_range.created_by_file_attente.count})",
    }
    rdvs_group_by_week.transform_keys { |key| [new_keys[key[0].to_sym], key[1]] }
  end

  def rdvs_group_by_status
    res = rdvs
      .where("starts_at < ?", Date.today)
      .where.not(status: :waiting)
      .group("status")
      .group_by_week("rdvs.starts_at", range: default_date_range, format: DEFAULT_FORMAT)
      .count
    rdvs_count_per_date = Hash.new(0)
    res.each { |key, rdvs_count| rdvs_count_per_date[key[1]] += rdvs_count }
    # ruby hashes are ordered and we care about the order here
    res_ordered = [:seen, :excused, :unknown, :notexcused]
      .reverse
      .map { |status| res.select { |key, _rdvs_count| key[0] == status.to_s } }
      .reduce(:merge)
    # normalize over 100 because chart.js does not support stacked: relative
    res_ordered.map do |key, rdvs_count|
      date_rdvs_count = rdvs_count_per_date[key[1]]
      [
        [::Rdv.human_enum_name(:status, key[0]), key[1]],
        date_rdvs_count.zero? ? 0 : (rdvs_count.to_f * 100 / date_rdvs_count).round
      ]
    end.to_h
  end

  def default_date_range
    self.class.default_date_range
  end

  def self.default_date_range
    Date.strptime("01/02/2020", "%d/%m/%Y").beginning_of_day..Time.zone.now.end_of_day
  end
end
