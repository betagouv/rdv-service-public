class Api::Visioplainte::PlagesOuvertureController < Api::Visioplainte::BaseController
  def index
    if params[:date_debut].blank? || params[:date_fin].blank?
      errors = ["Vous devez préciser les paramètres date_debut et date_fin"]
      render(json: { errors: errors }, status: :bad_request) and return
    end

    date_debut = Date.parse(params[:date_debut])
    date_fin = Date.parse(params[:date_fin])

    plages_ouvertures = plages_ouvertures_scope

    if params[:guichet_ids]
      plages_ouvertures = plages_ouvertures.where(agent_id: params[:guichet_ids])
    end

    plages_ouverture_occurences = plages_ouvertures.all_occurrences_for(date_debut..date_fin).map do |plage_ouverture, occurrence|
      {
        id: plage_ouverture.id,
        starts_at: occurrence.starts_at.iso8601,
        ends_at: occurrence.ends_at.iso8601,
        guichet_id: plage_ouverture.agent_id,
      }
    end

    render json: { plages_ouverture: plages_ouverture_occurences }
  end

  private

  def plages_ouvertures_scope
    PlageOuverture.joins(:agent).where(agent_id: Api::Visioplainte::GuichetsController.guichets.select(:id))
  end
end
