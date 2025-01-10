class RdvPlanBlueprint < Blueprinter::Base
  identifier :id

  field :url do |rdv_plan, _options|
    Rails.application.routes.url_helpers.edit_starts_at_agents_rdv_plan_url(rdv_plan, host: ENV["HOST"])
  end

  association :rdv, blueprint: RdvBlueprint
end
