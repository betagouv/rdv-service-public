class Api::Rdvinsertion::MotifCategoriesController < Api::Rdvinsertion::AgentAuthBaseController
  before_action :ensure_agent_is_rdv_insertion_super_admin, only: [:create]

  def create
    motif_category = MotifCategory.create!(motif_categories_params)
    render_record motif_category
  end

  private

  def ensure_agent_is_rdv_insertion_super_admin
    return if rdv_insertion_super_admin_emails.include?(current_agent.email)

    render_error :forbidden, error: :forbidden
  end

  def rdv_insertion_super_admin_emails
    ENV.fetch("RDV_INSERTION_SUPER_ADMIN_EMAILS", "").split(",").map(&:strip)
  end

  def motif_categories_params
    params.permit(:name, :short_name)
  end
end
