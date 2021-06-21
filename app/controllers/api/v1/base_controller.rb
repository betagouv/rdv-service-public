# frozen_string_literal: true

class Api::V1::BaseController < ActionController::Base
  skip_before_action :verify_authenticity_token
  include Pundit
  include DeviseTokenAuth::Concerns::SetUserByToken
  respond_to :json
  before_action :authenticate_api_v1_agent_with_token_auth!

  def pundit_user
    AgentContext.new(current_agent, current_organisation)
  end

  def current_organisation
    @current_organisation ||=
      if params[:organisation_id].blank?
        nil
      else
        current_agent.organisations.find_by(id: params[:organisation_id])
      end
  end

  def policy_scope(clasz)
    super([:agent, clasz])
  end

  def authorize(record, *args)
    super([:agent, record], *args)
  end

  def params
    params = super
    @page ||= params.delete(:page)&.to_i || 1
    @per ||= params.delete(:per)&.to_i || 100
    params
  end

  def render_record(record, **options)
    record_klass = record.class
    blueprint_klass = "#{record_klass.name}Blueprint".constantize
    root = record.class.model_name.element
    render json: blueprint_klass.render(record, root: root, **options)
  end

  def render_collection(objects)
    objects = objects.page(@page).per(@per)
    meta = {
      current_page: objects.current_page,
      next_page: objects.next_page,
      prev_page: objects.prev_page,
      total_pages: objects.total_pages,
      total_count: objects.total_count
    }

    objects_klass = objects.klass
    blueprint_klass = "#{objects_klass.name}Blueprint".constantize
    root = objects_klass.model_name.collection
    render json: blueprint_klass.render(objects, root: root, meta: meta)
  end

  # Rescuable exceptions

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    render(
      status: :forbidden,
      json: {
        errors: [{ base: :forbidden }],
        error_messages: [t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)]
      }
    )
  end

  def parameter_missing(exception)
    render(
      status: :unprocessable_entity,
      json: { success: false, errors: [exception.to_s] }
    )
  end

  def record_not_found(_)
    head :not_found
  end

  def record_invalid(exception)
    render(
      status: :unprocessable_entity,
      json: {
        success: false,
        errors: exception.record.errors.details,
        error_messages: exception.record.errors.map { "#{_1} #{_2}" }
      }
    )
  end
end
