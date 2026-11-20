class Agents::ApiTokensController < AgentAuthController
  layout "application_agent_config"

  before_action :check_api_tokens_feature_flag
  before_action { @active_agent_preferences_menu_item = :api_tokens }
  before_action :set_api_token, only: :destroy
  # la page affiche la clé en clair à la création : aucun cache navigateur/proxy
  before_action { response.headers["Cache-Control"] = "no-store" }

  def index
    @api_tokens = policy_scope(ApiToken, policy_scope_class: Agent::ApiTokenPolicy::Scope).order(created_at: :desc)
  end

  def new
    @api_token = ApiToken.new
    authorize @api_token, policy_class: Agent::ApiTokenPolicy
  end

  def create
    @api_token = current_agent.api_tokens.build(api_token_params)
    authorize @api_token, policy_class: Agent::ApiTokenPolicy

    return redirect_to_two_factor_verification unless AgentTwoFactorSessionState.recent_2fa?(session)

    if @api_token.save
      flash[:raw_api_token] = { "name" => @api_token.name, "token" => @api_token.raw_token }
      redirect_to agents_api_tokens_path, notice: "La clé d'API « #{@api_token.name} » a été créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @api_token, policy_class: Agent::ApiTokenPolicy
    return redirect_to_two_factor_verification unless AgentTwoFactorSessionState.recent_2fa?(session)

    @api_token.revoke!
    redirect_to agents_api_tokens_path, notice: "La clé d'API « #{@api_token.name} » a été révoquée."
  end

  private

  def check_api_tokens_feature_flag
    head :not_found unless current_agent.feature_enabled?("api_tokens")
  end

  def set_api_token
    @api_token = ApiToken.find(params[:id])
  end

  def api_token_params
    params.require(:api_token).permit(:name, :duration)
  end

  def redirect_to_two_factor_verification
    AgentTwoFactorSessionState.store_return_to!(session, agents_api_tokens_path)
    redirect_to new_agents_two_factor_verification_path
  end
end
