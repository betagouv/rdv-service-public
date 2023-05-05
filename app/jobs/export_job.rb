# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports

  include GoodJob::ActiveJobExtensions::Concurrency

  # Run export jobs one at a time to keep it light on Postgres
  good_job_control_concurrency_with(
    perform_limit: 1,
    key: "ExportJob"
  )
end
