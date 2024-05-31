module ApiException
  EXCEPTIONS = {
    # 400
    "ActionController::ParameterMissing" => { status: 400, message: "Missing Parameter" },

    # 401
    # "Unauthorized" => { status: 401, message: "Unauthorized" },

    # 403
    # "Forbidden" => { status: 403, message: "Forbidden" },

    # 404
    "ActiveRecord::RecordNotFound" => { status: 404, message: "Record Not Found" },

    # 422
    "UnprocessableEntity" => { status: 422, message: "Unprocessable Entity" },
    "ActiveRecord::RecordInvalid" => { status: 422, message: "Unprocessable Entity" },
  }.freeze

  class BaseError < StandardError
    def initialize(msg = nil)
      super
      @message = msg
    end

    def message
      @message || nil
    end
  end

  module Handler
    def self.included(klass)
      klass.class_eval do
        EXCEPTIONS.each do |exception_name, context|
          unless ApiException.const_defined?(exception_name)
            ApiException.const_set(exception_name, Class.new(BaseError))
            exception_name = "ApiException::#{exception_name}"
          end

          rescue_from exception_name do |exception|
            render status: context[:status], json: { success: false, message: context[:message], detail: exception.message }.compact
          end
        end
      end
    end
  end
end
