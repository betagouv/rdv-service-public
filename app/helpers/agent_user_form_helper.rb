# frozen_string_literal: true

module AgentUserFormHelper
  def agent_user_form_url(user)
    if user.persisted?
      admin_organisation_user_path(current_organisation, user)
    else
      admin_organisation_users_path(current_organisation)
    end
  end

  def agent_user_form_cancel_path(user)
    if user.persisted?
      admin_organisation_user_path(current_organisation, user)
    elsif user.relative? && user.responsible.persisted?
      admin_organisation_user_path(current_organisation, user.responsible)
    else
      admin_organisation_users_path(current_organisation)
    end
  end

  def agent_user_form_div_toggle_opts(user)
    {
      relative: {
        "data-togglable": true,
        "data-responsability-type": "relative",
        class: ("d-none" if user.responsability_type != :relative),
      },
      responsible: {
        "data-togglable": true,
        "data-responsability-type": "responsible",
        class: ("d-none" if user.responsability_type != :responsible),
      },
    }
  end
end
