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
    email = cookies.encrypted[:fiche_selection_email]&.fetch("email")
    return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } if email.blank?

    @fiches_usagers = candidate_fiches(email)
  end

  def submit_choix_fiche_usager
    email = consume_fiche_selection_email
    return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } if email.blank?

    chosen_user = candidate_fiches(email).find_by(id: params[:user_id])
    return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } unless chosen_user

    login_user(chosen_user)
  end

  private

  def storable_location? = false

  def dispatch_after_code_validation(email, valid_login_code)
    fiches = candidate_fiches(email).to_a

    if fiches.many?
      store_fiche_selection_email(email)
      redirect_to choix_fiche_usager_users_sessions_by_code_path
    elsif fiches.one?
      login_user(fiches.first)
    else
      # Aucune fiche existante sur ce territoire : création d'une nouvelle fiche (wizard uniquement).
      # En login spontané, LoginCodeRequestForm bloque l'envoi du code si aucun compte n'existe.
      return redirect_to new_user_session_path, flash: { error: "Échec de la connexion" } unless @rdv_wizard

      login_user(User.create_from_login_code!(email:, login_code: valid_login_code))
    end
  end

  def candidate_fiches(email)
    if @rdv_wizard
      # Dans le contexte d'un rdv_wizard, on restreint aux fiches usagers du même espace que le motif du rdv en cours de création
      # afin d'éviter d'avoir une même fiche usagers sur plusieurs espaces en même temps (ce qui est techniquement/historiquement possible mais pas souhaitable)
      User.loginable_by_code_for_email_in_territory_or_without_territory(email, territory_id: @rdv_wizard.motif.organisation.territory_id)
    else
      # En dehors du contexte d'un rdv_wizard (connexion explicite), on affiche toutes les fiches usagers associées à l'email, même celles d'autres espaces
      User.loginable_by_code_for_email(email).includes(organisations: :territory)
    end
  end

  def store_fiche_selection_email(email)
    cookies.encrypted[:fiche_selection_email] = { value: { "email" => email }, expires: 15.minutes.from_now }
  end

  def consume_fiche_selection_email
    email = cookies.encrypted[:fiche_selection_email]&.fetch("email")
    cookies.delete(:fiche_selection_email)
    email
  end

  def login_user(user)
    user.update!(latest_login_at: Time.zone.now)
    bypass_sign_in(user, scope: :user)
    redirect_to after_sign_in_path_for(user), flash: { success: "Connexion réussie" }
  end
end
