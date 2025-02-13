class RdvPlanBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :created_at, :updated_at

  field :url do |rdv_plan, _options|
    Rails.application.routes.url_helpers.agents_rdv_plan_url(rdv_plan, host: rdv_plan.planning_agent.domain.host_name)
  end

  field :rdv do |rdv_plan, _options|
    rdv = rdv_plan.rdv

    next if rdv.nil?

    {
      id: rdv.id,
      status: rdv.status,
      starts_at: rdv.starts_at.iso8601,
      location_type: rdv.motif.location_type,
    }
  end
end
