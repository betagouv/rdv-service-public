class Users::SessionsByCodeController < ApplicationController
  layout "application_narrow"

  include CanHaveRdvWizardContext

  def new
    @email = params[:email]
    return redirect_to(new_user_session_path) if @email.blank?

    @existing_login_code = LoginCode.most_recent_usable_for(email: @email)
  end

  def create
    email, code = params.require(:login_code).expect(:email, :code)
    validator = Users::LoginCodeValidator.new(email:, code:)

    if validator.valid?
      valid_login_code = validator.valid_login_code
      valid_login_code.update!(used_at: Time.zone.now)
      dispatch_after_code_validation(email, valid_login_code)
    elsif validator.should_redirect_to_code_request?
      redirect_to new_users_sessions_by_code_path(email:), flash: { error: validator.error }
    else
      @email = email
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code.errors.add(:base, validator.error)
      render :new
    end
  end

  def choix_fiche_usager
    email = session[:current_user_email]
    return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } if email.blank?

    @fiches_usagers = candidate_fiches(email)
  end

  def submit_choix_fiche_usager
    email      = session.delete(:current_user_email)
    first_name = session.delete(:wizard_first_name)
    last_name  = session.delete(:wizard_last_name)
    return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } if email.blank?

    chosen_user = candidate_fiches(email).find_by(id: params[:user_id])
    return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } unless chosen_user

    flash[:notice] = proche_notice(chosen_user) if chosen_user.names_differ_from?(first_name:, last_name:)
    login_user(chosen_user)
  end

  private

  def storable_location? = false

  def dispatch_after_code_validation(email, valid_login_code)
    fiches = candidate_fiches(email).to_a

    if fiches.many?
      store_selection_context(email, valid_login_code)
      redirect_to choix_fiche_usager_users_sessions_by_code_path
    elsif fiches.one?
      user = fiches.first
      flash[:notice] = proche_notice(user) if @rdv_wizard && user.names_differ_from?(first_name: valid_login_code.first_name, last_name: valid_login_code.last_name)
      login_user(user)
    else
      # Aucune fiche existante sur ce territoire : création d'une nouvelle fiche (wizard uniquement).
      return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } unless @rdv_wizard

      login_user(User.create_from_login_code!(email:, login_code: valid_login_code))
    end
  end

  def candidate_fiches(email)
    if @rdv_wizard
      # Dans le contexte d'un rdv_wizard, on restreint aux fiches usagers du même espace que le motif du rdv en cours de création
      # afin d'éviter d'avoir une même fiche usagers sur plusieurs espaces en même temps (ce qui est techniquement/historiquement possible mais pas souhaitable)
      User.loginable_by_code_for_email_in_territory(email, territory_id: @rdv_wizard.motif.organisation.territory_id)
    else
      # En dehors du contexte d'un rdv_wizard (connexion explicite), on affiche toutes les fiches usagers associées à l'email, même celles d'autres espaces
      User.loginable_by_code_for_email(email).includes(organisations: :territory)
    end
  end

  def store_selection_context(email, valid_login_code)
    session[:current_user_email] = email
    return unless @rdv_wizard

    session[:wizard_first_name] = valid_login_code.first_name
    session[:wizard_last_name]  = valid_login_code.last_name
  end

  def login_user(user)
    user.update!(latest_login_at: Time.zone.now)
    bypass_sign_in(user, scope: :user)
    redirect_to after_sign_in_path_for(user), flash: { success: "Connexion réussie" }
  end

  def proche_notice(user)
    # On suppose que si les prénoms ou noms diffèrent de la fiche usager existante, c'est que l'utilisateur se connecte pour un proche (et pas pour lui-même)
    "Vous êtes connecté en tant que #{user.full_name}. " \
      "Si ce rendez-vous est pour une autre personne, " \
      "utilisez le système de prise de rdv pour un proche à l'étape suivante."
  end
end
