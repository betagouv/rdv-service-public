# frozen_string_literal: true

class Api::V2::BaseController < ActionController::Base
  respond_to :json

  after_action :set_pagination_response_headers, if: -> { @pagination.present? }

  protected

  def check_parameters_presence(*parameters)
    missing_parameters = parameters.select { |param| params[param].blank? }
    render_error :bad_request, missing: missing_parameters.to_sentence if missing_parameters.any?
  end

  def render_error(status, error = { error: :unknown })
    render json: error, status: status
  end

  def render_record(record, **options)
    record_klass = record.class
    blueprint_klass = "#{record_klass.name}Blueprint".constantize
    render json: blueprint_klass.render(record, **options)
  end

  def render_collection(objects, blueprint_klass: nil)
    objects = objects.page(page).per(per)

    @pagination = {
      "X-RDV-Solidarites-Current-Page" => objects.current_page,
      "X-RDV-Solidarites-Next-Page" => objects.next_page,
      "X-RDV-Solidarites-Prev-Page" => objects.prev_page,
      "X-RDV-Solidarites-Total-Pages" => objects.total_pages,
      "X-RDV-Solidarites-Total-Count" => objects.total_count,
    }

    blueprint_klass = "#{objects.klass.name}Blueprint".constantize if blueprint_klass.blank?
    render json: blueprint_klass.render(objects)
  end

  def page
    @page ||= params[:page]&.to_i || 1
  end

  def per # TODO: SEB default to 20 and limit to 50
    @per ||= params[:per]&.to_i || 100
  end

  private

  def set_pagination_response_headers
    @pagination.each { |key, value| response.set_header(key, value) }
  end
end
