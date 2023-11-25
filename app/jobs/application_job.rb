class ApplicationJob < ActiveJob::Base
  include DefaultJobBehaviour

  queue_as :default
end
