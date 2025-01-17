class RdvPlanBlueprint < Blueprinter::Base
  identifier :id

  field :user_id

  field :url do |rdv_plan, _options|
    Rails.application.routes.url_helpers.agents_rdv_plan_url(rdv_plan, host: rdv_plan.planning_agent.domain.host_name)
  end

  field :rdv do |rdv_plan, _options|
    next if rdv_plan.rdv.nil?

    {
      id: rdv_plan.rdv_id,
      status: rdv_plan.rdv.status,
    }
  end
end
