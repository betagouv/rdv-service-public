# frozen_string_literal: true

module ApiResourcesRenderer
  extend ActiveSupport::Concern

  protected

  def render_record(record, **options)
    record_klass = record.class
    blueprint_klass = "#{record_klass.name}Blueprint".constantize
    root = record.class.model_name.element
    render json: blueprint_klass.render(record, root: root, **options)
  end

  def render_collection(objects, root: nil, blueprint_klass: nil)
    objects = objects.page(page).per(per)
    meta = {
      current_page: objects.current_page,
      next_page: objects.next_page,
      prev_page: objects.prev_page,
      total_pages: objects.total_pages,
      total_count: objects.total_count,
    }

    objects_klass = objects.klass
    blueprint_klass = "#{objects_klass.name}Blueprint".constantize if blueprint_klass.blank?
    root = objects_klass.model_name.collection if root.blank?
    render json: blueprint_klass.render(objects, root: root, meta: meta)
  end

  def page
    @page ||= params[:page]&.to_i || 1
  end

  def per
    @per ||= params[:per]&.to_i || 100
  end
end
