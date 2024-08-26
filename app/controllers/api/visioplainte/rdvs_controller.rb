class Api::Visioplainte::RdvsController < Api::Visioplainte::BaseController
  def create
    creneau = Users::CreneauxSearch.creneau_for(
      user: nil,
      starts_at: Time.zone.parse(params[:starts_at]),
      motif: motif,
      lieu: nil
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

      rdv = Rdv.new(
        participations_attributes: [
          {
            user: user,
            send_lifecycle_notifications: false,
            send_reminder_notification: false,
          },
        ],
        starts_at: creneau.starts_at,
        motif: creneau.motif,
        agents: [creneau.agent],
        organisation: motif.organisation,
        created_by: user,
        ends_at: creneau.ends_at
      )
      if rdv.save
        render json: Visioplainte::RdvBlueprint.render(rdv), status: :created
      else
        render json: { errors: rdv.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    head :no_content
  end

  def cancel
    render json: Visioplainte::RdvBlueprint.render(rdv(:excused)), status: :ok
  end

  private

  # duplicated from creneaux controller
  def motif
    @motif ||= Motif.joins(organisation: :territory).where(territories: { name: Territory::VISIOPLAINTE_NAME })
      .joins(:service).find_by(service: { name: service_names[params["service"]] })
  end

  # duplicated from creneaux controller
  def service_names
    {
      "Police" => "Police Nationale",
      "Gendarmerie" => "Gendarmerie Nationale",
    }
  end

  def rdv(status)
    # Des données de test pour documenter l'api.
    Rdv.new(
      id: 123,
      users: [User.new(id: 456)],
      agents: [Agent.new(id: 789, last_name: "Guichet 3")],
      created_at: Time.zone.now,
      starts_at: params[:starts_at],
      duration_in_min: 45,
      status: status
    )
  end
end
