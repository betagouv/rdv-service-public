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
        class: ("d-none" if user.responsability_type != :relative)
      },
      responsible: {
        "data-togglable": true,
        "data-responsability-type": "responsible",
        class: ("d-none" if user.responsability_type != :responsible)
      }
    }
  end

  def agent_user_form_input_toggle_opts(user)
    %i[responsible relative relative_new relative_existing].index_with do |key|
      send("agent_user_form_input_#{key}", user)
    end
  end

  def agent_user_form_input_responsible(user)
    {
      input_html: {
        "data-togglable": true,
        "data-responsability-type": "responsible"
      },
      disabled: user.responsability_type != :responsible
    }
  end

  def agent_user_form_input_relative(user)
    {
      input_html: {
        "data-togglable": true,
        "data-responsability-type": "relative"
      },
      disabled: user.responsability_type != :relative
    }
  end

  def agent_user_form_input_relative_new(user)
    {
      input_html: {
        "data-togglable": true,
        "data-responsability-type": "relative",
        "data-relative-type": "new"
      },
      disabled: !(user.responsability_type == :relative && user.responsible.new_and_blank?)
    }
  end

  def agent_user_form_input_relative_existing(user)
    {
      input_html: {
        "data-togglable": true,
        "data-responsability-type": "relative",
        "data-relative-type": "existing"
      },
      disabled: !(user.responsability_type == :relative && !user.responsible.new_and_blank?)
    }
  end
end
