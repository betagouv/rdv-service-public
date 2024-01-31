class AgentPrescripteurRdvWizard
  attr_reader :query_params

  def initialize(query_params:, agent_prescripteur:, domain:, current_organisation:)
    @query_params = query_params
    @agent_prescripteur = agent_prescripteur
    @domain = domain
    @current_organisation = current_organisation
  end

  def motif
    @motif ||= rdv.motif
  end

  def invitation?
    false
  end

  def params_to_selections
    query_params
  end

  def create!
    ActiveRecord::Base.transaction do
      if @rdv.collectif?
        create_participation!
      else
        create_rdv!
      end

      PrescripteurMailer.rdv_created(participation, @domain.id).deliver_later
    end
  end

  def rdv
    @rdv ||= if query_params[:rdv_collectif_id].present?
               Rdv.collectif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.find(query_params[:rdv_collectif_id])
             else
               Rdv.new(query_params.slice(:starts_at, :user_ids, :motif_id, :lieu_id))
             end
  end

  def participations
    return @rdv.participations if @rdv.participations.present?

    @rdv.participations = users.map { Participation.new(rdv: @rdv, user: _1, created_by: @agent_prescripteur) }
  end

  def participation
    participations.first
  end

  def creneau
    @creneau ||= Users::CreneauSearch.creneau_for(
      user: users&.first,
      motif: motif,
      lieu: lieu,
      starts_at: rdv.starts_at,
      geo_search: geo_search
    )
  end

  def users
    query_params[:user_ids]&.compact_blank&.map { User.find(_1) }
  end

  private

  def create_rdv!
    rdv.assign_attributes(
      created_by: @agent_prescripteur,
      organisation: motif.organisation,
      agents: [creneau.agent],
      duration_in_min: motif&.default_duration_in_min
    )
    rdv.participations.map(&:set_default_notifications_flags)
    rdv.save!

    @participation = rdv.participations.first
    Notifiers::RdvCreated.perform_with(rdv, @agent_prescripteur)
  end

  def create_participation!
    participation.create_and_notify!(@agent_prescripteur)
  end

  def lieu
    @lieu ||= Lieu.find_by(id: query_params[:lieu_id])
  end

  def geo_search
    @geo_search ||= Users::GeoSearch.new(
      departement: query_params[:departement],
      city_code: query_params[:city_code],
      street_ban_id: query_params[:street_ban_id]
    )
  end
end
