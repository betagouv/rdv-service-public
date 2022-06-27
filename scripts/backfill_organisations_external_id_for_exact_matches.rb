# frozen_string_literal: true

# Usage :
# scalingo run "rails runner scripts/backfill_organisations_external_id.rb" --app production-rdv-solidarites --region osc-secnum-fr1 --file tmp/export-cnfs.csv
# A one-off script to backfill organisations.external_ids
# This script can be deleted after we run it once

class BackfillOrganisationExternalId
  class ConseillerNumerique
    include ActiveModel::Model

    attr_accessor :email, :first_name, :last_name, :external_id
  end

  class Structure
    include ActiveModel::Model

    attr_accessor :name, :address, :external_id
  end

  def initialize(conseiller_numerique_attributes, conseillers_numeriques)
    structure_attributes = conseiller_numerique_attributes.delete(:structure)
    @conseiller_numerique = ConseillerNumerique.new(conseiller_numerique_attributes)
    @structure = Structure.new(structure_attributes)
    @conseillers_numerique = conseillers_numeriques
  end

  def self.process!(conseiller_numerique_attributes)
    new(conseiller_numerique_attributes).process!
  end

  def process!
    ActiveRecord::Base.transaction do
      return if Organisation.find_by(external_id: @structure.external_id)
      return unless agent

      # We don't handle the case of an agent in multiple organisations
      if agent.organisations.count > 1
        puts "Warning: L'agent #{agent.id} est dans plusieurs organisations."
      end

      @organisation = agent.organisations.first
      if exact_match?
        @organisation.update!(external_id: @structure.external_id)
      else
        backfill_organisation_with_multiple_agents
      end
    end
  end

  private

  def exact_match?
    # The agent is the only cnfs for the organisation (secretaires may have been invited)
    @organisation.agents.where.not(external_id: nil) == [agent]
  end

  def agent
    @agent ||= Agent.find_by(external_id: @conseiller_numerique.external_id)
  end

  def backfill_organisation_with_multiple_agents
    cnfs_emails_that_should_be_in_organisation = @conseillers_numeriques.select do |cnfs|
      cnfs["Id de la structure"] == @structure.external_id
    end.map do |cnfs|
      cnfs["Email @conseiller-numerique.fr"]
    end.sort

    cnfs_emails_that_are_in_organisation = @organisation.agents.pluck(:external_id).uniq.compact.sort

    grouped_by_mistake = cnfs_emails_that_are_in_organisation == cnfs_emails_that_should_be_in_organisation

    unless grouped_by_mistake
      @organisation.update!(external_id: @structure.external_id)
      return
    end

    # The agents were grouped by mistake
    puts "#{cnfs_emails_that_are_in_organisation} ont été groupés ensemble par erreur"
    puts "Ce cas sera géré dans un autre script"

    most_active_agent_id = organisation.rds.joins(:agents_rdvs).group(:agent_id).where(organisation_id: 719).count.sort_by { |_k, v|; -v }.first.first

    if most_active_agent_id == agent.id
      @organisation.update!(external_id: @structure.external_id)
    end
  end
end

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |conseiller_numerique|
  BackfillOrganisationExternalId.process!({
    external_id: conseiller_numerique["Email @conseiller-numerique.fr"],
    email: conseiller_numerique["Email @conseiller-numerique.fr"],
    first_name: conseiller_numerique["Prénom"],
    last_name: conseiller_numerique["Nom"],
    structure: {
      external_id: conseiller_numerique["Id de la structure"],
      name: conseiller_numerique["Nom de la structure"],
      address: conseiller_numerique["Adresse de la structure"],
    },
  }.with_indifferent_access, conseillers_numeriques)
  puts "Backfill effectué pour #{conseiller_numerique['Id de la structure']} (#{conseiller_numerique['Id de la structure']})"
end
