class Api::Visioplainte::RdvsController < Api::Visioplainte::BaseController
  def index
    rdvs = []
    render json: {
      rdvs: rdvs.map do |rdv|
        Visioplainte::RdvBlueprint.render(rdv)
      end,
    }
  end

  def create
    creneau = CreneauxSearch::ForUser.creneau_for(
      starts_at: Time.zone.parse(params[:starts_at]),
      motif: motif
    )
    if creneau.blank?
      errors = { errors: ["Pas de créneau disponible pour ce service à la date demandée"] }

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
    Rdv.joins(organisation: :territory).where(territories: { name: Territory::VISIOPLAINTE_NAME })
      .find_by(id: params[:id])
  end

  def motif
    @motif ||= Api::Visioplainte::CreneauxController.find_motif(params[:service])
  end
end
