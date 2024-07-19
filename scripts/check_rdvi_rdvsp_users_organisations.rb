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

organisations_only_in_rdvsp = Hash.new { |hash, key| hash[key] = [] }
organisations_not_in_rdvsp = Hash.new { |hash, key| hash[key] = [] }

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

    organisations_not_in_rdvsp_current.each do |org_id|
      organisations_not_in_rdvsp[org_id] << user.id
    end

    organisations_only_in_rdvsp_current.each do |org_id|
      organisations_only_in_rdvsp[org_id] << user.id
    end
  end
end

file_path_not_in_rdvsp = Rails.root.join("organisations_not_in_rdvsp.json")
file_path_only_in_rdvsp = Rails.root.join("organisations_only_in_rdvsp.json")

File.write(file_path_not_in_rdvsp, JSON.pretty_generate(organisations_not_in_rdvsp))
File.write(file_path_only_in_rdvsp, JSON.pretty_generate(organisations_only_in_rdvsp))

logger.info "Vérification des données terminée et fichiers JSON générés."

puts "Les fichiers JSON ont été générés et sauvegardés aux emplacements suivants :"
puts "Organisations en moins dans RDVSP : #{file_path_not_in_rdvsp}"
puts "Organisations en plus dans RDVSP : #{file_path_only_in_rdvsp}"
