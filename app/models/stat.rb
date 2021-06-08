# frozen_string_literal: true

class Stat
  include ActiveModel::Model
  attr_accessor :agents, :organisations, :users, :rdvs

  DEFAULT_FORMAT = "%d/%m/%Y"

  delegate :active, to: :users, prefix: true

  def users_group_by_week
    users.active.group_by_week("users.created_at", format: DEFAULT_FORMAT).count
  end

  def organisations_group_by_week
    organisations.group_by_week("organisations.created_at", format: DEFAULT_FORMAT).count
  end

  def agents_for_default_range
    agents.active
  end

  def agents_group_by_week
    agents.active.group_by_week("agents.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week
    rdvs.group(:created_by).group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_type
    rdvs.joins(:motif).group("motifs.location_type").group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count.transform_keys { |key| [I18n.t(Motif.location_types.invert[key[0]]), key[1]] }
  end

  def rdvs_group_by_departement
    rdvs.joins(organisation: :territory).order("territories.departement_number").group("territories.departement_number").group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_service
    rdvs.joins(motif: :service).group("services.name").group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week_fr
    new_keys = {
      agent: "Agent (#{rdvs.created_by_agent.count})",
      user: "Usager (#{rdvs.created_by_user.count})",
      file_attente: "File d'attente (#{rdvs.created_by_file_attente.count})"
    }
    rdvs_group_by_week.transform_keys { |key| [new_keys[key[0].to_sym], key[1]] }
  end

  def rdvs_group_by_status
    res = rdvs
      .where("starts_at < ?", Time.zone.today)
      .where.not(status: :waiting)
      .group("status")
      .group_by_week("rdvs.starts_at", format: DEFAULT_FORMAT)
      .count
    rdvs_count_per_date = Hash.new(0)
    res.each { |key, rdvs_count| rdvs_count_per_date[key[1]] += rdvs_count }
    # ruby hashes are ordered and we care about the order here
    res_ordered = %i[seen excused unknown notexcused]
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
end
