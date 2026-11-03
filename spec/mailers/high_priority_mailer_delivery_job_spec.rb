RSpec.describe HighPriorityMailerDeliveryJob do
  specify "Agents::LoginCodeMailer enqueue l'envoi de l'email en haute prio" do
    login_code = create(:login_code)
    Agents::LoginCodeMailer.with(login_code:).login_code.deliver_later
    job = enqueued_jobs.last
    expect(job["job_class"]).to eq("HighPriorityMailerDeliveryJob")
    expect(job["priority"]).to eq(-100)
    expect(job["queue_name"]).to eq("latency_30s")
  end

  specify "Users::LoginCodeMailer enqueue l'envoi de l'email avec le job haute priorité" do
    login_code = create(:login_code)
    Users::LoginCodeMailer.with(login_code:).login_code.deliver_later
    job = enqueued_jobs.last
    expect(job["job_class"]).to eq("HighPriorityMailerDeliveryJob")
    expect(job["priority"]).to eq(-100)
    expect(job["queue_name"]).to eq("latency_30s")
  end
end
