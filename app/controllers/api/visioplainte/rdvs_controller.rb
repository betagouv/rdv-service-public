# cf docs/interconnexions/visioplainte.md

class Api::Visioplainte::RdvsController < Api::Visioplainte::BaseController
  def index # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    if params[:ids].blank? && (params[:date_debut].blank? || params[:date_fin].blank?)
      errors = ["Vous devez préciser le paramètre ids ou les paramètres date_debut et date_fin"]
      render(json: { errors: errors }, status: :bad_request) and return
    end

    rdvs = authorized_rdv_scope

    if params[:ids].present?
      rdvs = rdvs.where(id: params[:ids])
    end

    if params[:date_debut].present? && params[:date_fin].present?
      rdvs = rdvs.where("starts_at >= ?", Time.zone.parse(params[:date_debut])).where("starts_at <= ?", Time.zone.parse(params[:date_fin]))
    end

    if params[:guichet_ids]
      rdvs = rdvs.joins(:agents_rdvs).where(agents_rdvs: { agent_id: params[:guichet_ids] })
    end

    render json: Visioplainte::RdvBlueprint.render(rdvs, root: :rdvs)
  end

  def create
    creneau = CreneauxSearch::ForUser.creneau_for(
      starts_at: Time.zone.parse(params[:starts_at]),
      motif: motif
    )
    if creneau.blank?
      errors = { errors: ["Pas de créneau disponible à la date demandée"] }

      render(json: errors, status: :unprocessable_entity) and return
    end

    Rdv.transaction do
      # Pour la visioplainte, les données des usagers sont uniquement enregistrées dans le téléservice Visioplainte
      # On ne stocke aucune de leurs données chez nous, donc on crée juste un usager pour faire passer les validations.
      # Cette décision est motivée par le fait que les agents qui assurent les rdv n'utilisent pas non plus directement notre application
      user = User.create!(first_name: "Usager Anonyme", last_name: "Visioplainte")

      rdv = creneau.build_rdv
      rdv.assign_attributes(
        created_by: user,
        participations_attributes: [
          {
            user: user,
            send_lifecycle_notifications: false,
            send_reminder_notification: false,
          },
        ]
      )
      if rdv.save
        render json: Visioplainte::RdvBlueprint.render(rdv), status: :created
      else
        render json: { errors: rdv.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    rdv = find_rdv

    if rdv.blank?
      render(json: { errors: ["Pas de rdv pour cet id"] }, status: :not_found)
    else
      rdv.destroy!
      head :no_content
    end
  end

  def cancel
    rdv = find_rdv

    if rdv.blank?
      render(json: { errors: ["Pas de rdv pour cet id"] }, status: :not_found)
    else
      rdv.update_and_notify(rdv.users.first, status: "excused")
      render json: Visioplainte::RdvBlueprint.render(rdv), status: :ok
    end
  end

  private

  def find_rdv
    authorized_rdv_scope.find_by(id: params[:id])
  end

  def authorized_rdv_scope
    Rdv.joins(organisation: :territory).where(territories: { name: Territory::VISIOPLAINTE_NAME })
  end

  def motif
    @motif ||= Api::Visioplainte::CreneauxController.find_motif
  end
end
