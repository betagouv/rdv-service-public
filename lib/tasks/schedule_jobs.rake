# frozen_string_literal: true

desc "Schedule all cron jobs"
task schedule_jobs: :environment do
  # See https://github.com/codez/delayed_cron_job#scheduling-trigger
  # Need to load all jobs definitions in order to find subclasses
  glob = Rails.root.join("app/jobs/**/*_job.rb")
  Dir.glob(glob).sort.each { |file| require file }
  CronJob.subclasses.each(&:schedule)
end

# invoke schedule_jobs automatically after every migration and schema load.
unless Rails.env.test?
  %w[db:migrate db:schema:load].each do |task|
    Rake::Task[task].enhance do
      Rake::Task["schedule_jobs"].invoke
    end
  end
end
