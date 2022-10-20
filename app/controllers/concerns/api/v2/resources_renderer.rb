# frozen_string_literal: true

module Api::V2::ResourcesRenderer
  extend ActiveSupport::Concern

  included do
    after_action :set_pagination_response_headers, if: -> { @pagination.present? }
  end

  protected

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

  private

  def page
    @page ||= params[:page]&.to_i || 1
  end

  def per
    @per ||= params[:per]&.to_i || 100
  end

  def set_pagination_response_headers
    @pagination.each { |key, value| response.set_header(key, value) }
  end
end
