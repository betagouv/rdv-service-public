class Api::V1::BaseController < ActionController::Base
  include ExplicitPunditConcern

  respond_to :json

  PAGINATE_PER = 100

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
    root = record.class.model_name.element
    render json: blueprint_klass.render(record, root: root, **options)
  end

  def render_collection(objects, root: nil, blueprint_klass: nil)
    objects = objects.page(page_number).per(PAGINATE_PER)
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

  def page_number
    params[:page].presence&.to_i || 1
  end
end
