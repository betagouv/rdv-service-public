class Admin::VersionsController < AgentAuthController
  layout false # loaded and injected in the pages through AJAX

  before_action :set_resource
  skip_after_action :verify_policy_scoped, only: :index

  def index
    authorize(@resource, :show?)
    @augmented_versions = PaperTrailAugmentedVersion
      .for_resource(@resource, attributes_whitelist: params[:only])
      .select(&:changes?)
      .reverse
  end

  private

  def set_resource
    @resource = Rdv.find(params[:rdv_id]) if params[:rdv_id].present?
    raise unless @resource
  end
end
