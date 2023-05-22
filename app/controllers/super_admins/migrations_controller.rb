# frozen_string_literal: true

module SuperAdmins
  class MigrationsController < ApplicationController
    def new
      @agent = Agent.find(params[:agent_id])
    end

    def create
      agent = Agent.find(params[:agent_id])

      new_organisation = Organisation.find(params[:new_organisation_id])
      old_organisation = Organisation.find(params[:old_organisation_id])

      if migrate_agent!(agent: agent, old_organisation: old_organisation, new_organisation: new_organisation)
        flash[:notice] = "#{agent.full_name} et toutes ses données de #{old_organisation.name} ont été migrés vers #{new_organisation.name}"
        redirect_to super_admins_agent_path(params[:agent_id])
      else
        new
        render :new
      end
    end

    private

    def migrate_agent!(agent:, old_organisation:, new_organisation:)
      if old_organisation.territory_id != new_organisation.territory_id
        flash[:error] = "#{new_organisation.name} n'est pas dans le même territoire que #{old_organisation.name}, vous ne pouvez donc pas migrer d'agent entre ces deux organisations"
        return false
      end

      if rdvs_with_other_agents(agent, old_organisation).any?
        flash[:error] = "Cet agent a des RDVs avec d'autres agents de cette organisation, et ne peut donc pas être migré automatiquement.\
          Contactez l'équipe technique pour vous aider à faire cette migration."
        return false
      end

      # rubocop:disable Rails/SkipsModelValidations
      ActiveRecord::Base.transaction do
        # migrer les plages d'ouverture
        plage_ouvertures_for_organisation = PlageOuverture.where(agent_id: agent.id)
        plage_ouvertures_for_organisation.where(organisation: old_organisation).update_all(organisation_id: new_organisation.id)

        # creer des duplicatas de motifs, et y associer les plages d'ouvertures, et les rdvs
        Motif.joins(rdvs: :agents_rdvs).where(agents_rdvs: { agent_id: agent.id }).distinct.find_each do |old_motif|
          new_motif = old_motif.dup
          new_motif.organisation = new_organisation
          new_motif.save!

          MotifsPlageOuverture.where(motif_id: old_motif, plage_ouverture_id: plage_ouvertures_for_organisation).update_all(motif_id: new_motif.id)

          Rdv.joins(:agents_rdvs).where(agents_rdvs: { agent_id: agent.id }, motif: old_motif).update_all(motif_id: new_motif.id)
        end

        Rdv.joins(:agents_rdvs).where(agents_rdvs: { agent_id: agent.id }, rdvs: { organisation_id: old_organisation.id }).update_all(organisation_id: new_organisation.id)

        # migrer les lieux (en espérant qu'il n'y ai pas de lieux utilisés par plusieurs organisations différentes)
        Lieu.joins(rdvs: :agents_rdvs).where(agents_rdvs: { agent_id: agent.id }).where(organisation: old_organisation).update_all(organisation_id: new_organisation.id)

        # et ajouter les usagers
        User.joins(rdvs_users: { rdv: :agents_rdvs }).where(agents_rdvs: { agent_id: agent.id }).find_each do |user|
          user.add_organisation(new_organisation)
        end

        old_role = AgentRole.find_by(agent_id: agent.id, organisation_id: params[:old_organisation_id])
        AgentRole.create!(agent_id: agent.id, organisation: new_organisation, level: old_role.level)
        old_role.delete
      end
      # rubocop:enable Rails/SkipsModelValidations
    end

    def rdvs_with_other_agents(agent, old_organisation)
      AgentsRdv.joins(:rdv).where(
        agent_id: agent.id,
        rdvs: { organisation_id: old_organisation.id }
      ).joins(
        "JOIN agents_rdvs AS other_agents_rdvs
         ON agents_rdvs.rdv_id = other_agents_rdvs.rdv_id
           AND agents_rdvs.agent_id != other_agents_rdvs.agent_id"
      )
    end
  end
end
