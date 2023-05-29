# frozen_string_literal: true

class Stat
  include ActiveModel::Model
  attr_accessor :agents, :organisations, :users, :rdvs, :receipts

  DEFAULT_FORMAT = "%d/%m/%Y"

  def agents_for_default_range
    agents
  end

  def rdvs_group_by_week
    rdvs.group(:created_by).group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_type
    rdvs.joins(:motif).group("motifs.location_type").group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count.transform_keys { |key| [I18n.t(Motif.location_types.invert[key[0]]), key[1]] }
  end

  def rdvs_group_by_territory_name
    rdvs.joins(organisation: :territory).order("territories.name").group("territories.name").group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_service
    rdvs.joins(motif: :service).group("services.name").group_by_week("rdvs.created_at", format: DEFAULT_FORMAT).count
  end

  def rdvs_group_by_week_fr
    new_keys = {
      agent: "Agent (#{rdvs.created_by_agent.count})",
      user: "Usager (#{rdvs.created_by_user.count})",
      file_attente: "File d'attente (#{rdvs.created_by_file_attente.count})",
      prescripteur: "Prescripteur (#{rdvs.created_by_prescripteur.count})",
    }
    rdvs_group_by_week.transform_keys { |key| [new_keys[key[0].to_sym], key[1]] }
  end

  def rdvs_group_by_status
    res = rdvs
      .where("starts_at < ?", Time.zone.today)
      .group("status")
      .group_by_week("rdvs.starts_at", format: DEFAULT_FORMAT)
      .count
    rdvs_count_per_date = Hash.new(0)
    res.each { |key, rdvs_count| rdvs_count_per_date[key[1]] += rdvs_count }
    # ruby hashes are ordered and we care about the order here
    res_ordered = %i[unknown seen excused revoked noshow]
      .reverse
      .map { |status| res.select { |key, _rdvs_count| key[0] == status.to_s } }
      .reduce(:merge)
    # normalize over 100 because chart.js does not support stacked: relative
    res_ordered.to_h do |key, rdvs_count|
      date_rdvs_count = rdvs_count_per_date[key[1]]
      [
        [::Rdv.human_attribute_value(:status, key[0]), key[1]],
        date_rdvs_count.zero? ? 0 : (rdvs_count.to_f * 100 / date_rdvs_count).round,
      ]
    end
  end

  def rdvs_group_by_rdv_users_status
    res = RdvsUser
      .joins(:rdv)
      .where(rdv: rdvs)
      .where("rdvs.starts_at < ?", Time.zone.today)
      .group("status")
      .group_by_week("rdvs.starts_at", format: DEFAULT_FORMAT)
      .count
    rdvs_count_per_date = Hash.new(0)
    res.each { |key, rdvs_count| rdvs_count_per_date[key[1]] += rdvs_count }
    # ruby hashes are ordered and we care about the order here
    res_ordered = %i[unknown seen excused revoked noshow]
      .reverse
      .map { |status| res.select { |key, _rdvs_count| key[0] == status.to_s } }
      .reduce(:merge)
    # normalize over 100 because chart.js does not support stacked: relative
    res_ordered.to_h do |key, rdvs_count|
      date_rdvs_count = rdvs_count_per_date[key[1]]
      [
        [::Rdv.human_attribute_value(:status, key[0]), key[1]],
        date_rdvs_count.zero? ? 0 : (rdvs_count.to_f * 100 / date_rdvs_count).round,
      ]
    end
  end

  def receipts_group_by(attribute)
    receipts
      .group(attribute)
      .group_by_day(:created_at)
      .count
      .transform_keys { |key| [Receipt.human_attribute_value(attribute, key[0]), key[1]] }
  end

  def active_agents_group_by_month
    rdvs.joins(:agents_rdvs).where("rdvs.starts_at < ?", Time.zone.now).group_by_month("rdvs.starts_at").count("distinct agents_rdvs.agent_id")
  end
end
