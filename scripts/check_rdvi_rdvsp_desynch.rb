#!/usr/bin/env ruby

require "json"
require "logger"
require_relative "../config/environment"

log_file_path = Rails.root.join("rdvi_rdvsp_coherence.log")
logger = Logger.new(log_file_path)
logger.level = Logger::INFO

file_path = Rails.root.join("rdvsp_users_ids.json")
json_data = File.read(file_path)
users_data = JSON.parse(json_data)

desynch_users = Hash.new { |hash, key| hash[key] = [] }

batch_size = 1000

users_data.each_slice(batch_size) do |user_batch|
  user_batch.each do |user_data|
    user_id_from_rdvi = user_data["rdv_solidarites_user_id"]
    organisation_ids_from_rdvi = user_data["rdv_solidarites_organisation_ids"]

    user = User.find_by(id: user_id_from_rdvi)

    if user.nil?
      user = User.unscoped.find_by(id: user_id_from_rdvi)
      if user&.deleted_at
        logger.info "User avec user_id_from_rdvi #{user_id_from_rdvi} a été supprimé (soft deleted)"
      else
        logger.warn "User avec user_id_from_rdvi #{user_id_from_rdvi} introuvable (??? NE DOIT PAS ARRIVER ???)"
      end
      next
    end

    organisation_ids_from_rdvsp = user.organisations.where(verticale: "rdv_insertion").pluck(:id)
    organisations_not_in_rdvsp_current = organisation_ids_from_rdvi - organisation_ids_from_rdvsp
    organisations_only_in_rdvsp_current = organisation_ids_from_rdvsp - organisation_ids_from_rdvi

    next unless organisations_not_in_rdvsp_current.any? || organisations_only_in_rdvsp_current.any?

    desynch_users[user.id] << {
      updated_at: user.updated_at,
      organisations_uniquement_dans_rdvi: Organisation.where(id: organisations_not_in_rdvsp_current).pluck(:name),
      organisations_uniquement_dans_rdvsp: Organisation.where(id: organisations_only_in_rdvsp_current).pluck(:name),
    }
  end
end

desynch_users = desynch_users.sort_by { |_user_id, data| data.first[:updated_at] }.reverse.to_h

desynch_file = Rails.root.join("desynch_users.json")

File.write(desynch_file, JSON.pretty_generate(desynch_users))
# display desynch users count
logger.info "Nombre d'utilisateurs désynchronisés: #{desynch_users.count} au #{Time.zone.now}"
