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
    organisation_not_in_rdvsp = organisation_ids_from_rdvi - organisation_ids_from_rdvsp
    organisation_only_in_rdvsp = organisation_ids_from_rdvsp - organisation_ids_from_rdvi

    unless organisation_only_in_rdvsp.empty?
      logger.info "User #{user.id} a des organisations en plus dans RDVSP : #{organisation_only_in_rdvsp.join(', ')}"
    end

    unless organisation_not_in_rdvsp.empty?
      logger.info "User #{user.id} a des organisations en moins dans RDVSP : #{organisation_not_in_rdvsp.join(', ')}"
    end
  end
end

logger.info "Vérification des données terminée."
