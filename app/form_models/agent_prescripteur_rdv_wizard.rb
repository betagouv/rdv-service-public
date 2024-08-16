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
               Rdv.new(query_params.slice(:starts_at, :motif_id, :lieu_id))
             end
  end

  def participation
    @participation ||= Participation.new(rdv: @rdv, user: user, created_by: @agent_prescripteur, created_by_agent_prescripteur: true)
  end

  def creneau
    @creneau ||= Users::CreneauxSearch.creneau_for(
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

  def user
    user_ids = Array(query_params[:user_ids]).compact_blank
    users = User.where(id: user_ids)
    if users.count > 1
      Sentry.capture_message("AgentPrescripteurRdvWizard a plusieurs user_ids: #{user_ids.inspect}", fingerprint: ["several_user_ids"])
    end
    users.first
  end

  private

  def create_rdv!
    rdv.assign_attributes(
      created_by: @agent_prescripteur,
      organisation: motif.organisation,
      agents: [creneau.agent],
      duration_in_min: motif&.default_duration_in_min
    )
    rdv.participations = [participation]

    rdv.save!

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
