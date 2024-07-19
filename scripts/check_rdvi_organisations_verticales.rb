#!/usr/bin/env ruby

require "json"
require "logger"
require_relative "../config/environment"

log_file_path = Rails.root.join("rdvi_rdvsp_verticales.log")
logger = Logger.new(log_file_path)
logger.level = Logger::INFO

file_path = Rails.root.join("rdvsp_organisations_ids.json")
json_data = File.read(file_path)
organisations_data = JSON.parse(json_data)

batch_size = 1000

organisations_data.each_slice(batch_size) do |organisation_batch|
  organisation_batch.each do |organisation_data|
    organisation_id_from_rdvi = organisation_data["rdv_solidarites_organisation_id"]

    organisation = Organisation.find_by(id: organisation_id_from_rdvi)

    if organisation.nil?
      logger.warn "Organisation avec id #{organisation_id_from_rdvi} introuvable"
    end

    unless organisation.rdv_insertion?
      logger.info "Organisation #{organisation.id} n'est pas une organisation RDVI"
    end
  end
end

logger.info "Vérification des données terminée."
