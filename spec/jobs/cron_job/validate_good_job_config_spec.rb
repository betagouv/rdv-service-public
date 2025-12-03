# rubocop:disable RSpec/DescribeClass
RSpec.describe "Good Job CRON keys" do
  it "only contains classes that have the interface of a job" do
    job_classes = Rails.configuration.good_job.cron.values.map { _1[:class] }
    job_classes.each do |job_class|
      job = nil
      expect { job = job_class.constantize.new }.not_to raise_error
      if job
        expect(job.respond_to?(:perform)).to be(true)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
