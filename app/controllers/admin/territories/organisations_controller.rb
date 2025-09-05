class Admin::Territories::OrganisationsController < Admin::Territories::BaseController
  def index
    @organisations = organisations
  end

  def select_for_close
    sanitized_outer_join = ApplicationRecord.sanitize_sql(
      [
        "LEFT OUTER JOIN rdvs ON (rdvs.organisation_id = organisations.id AND rdvs.status in (:statuses) AND rdvs.starts_at  > :starts_at)",
        { statuses: Rdv::NOT_CANCELLED_STATUSES, starts_at: Time.zone.now },
      ]
    )
    @organisations = organisations.joins(sanitized_outer_join).where.missing(:rdvs).uniq

    if @organisations.empty?
      skip_authorization
    else

      authorize(@organisations.first, :close?, policy_class: Agent::OrganisationPolicy)
    end
  end

  def close
    organisation = Organisation.find(params[:organisation_id])
    authorize(organisation, :close?, policy_class: Agent::OrganisationPolicy)

    flash[:success] = "L'organisation a été fermée."
    redirect_to admin_territory_organisations_path(organisation.territory)
  end

  private

  def organisations
    policy_scope(current_agent.organisations, policy_scope_class: Agent::OrganisationPolicy::Scope)
      .where(territory: current_territory)
      .ordered_by_name
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
