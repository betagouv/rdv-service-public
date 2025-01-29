class CronMonitor
  def self.expected_enqueued_ats(cron_str, time_range)
    fugit_obj = Fugit.parse_cronish(cron_str)
    expected_enqueued_ats = []
    t = time_range.end
    loop do
      t = fugit_obj.previous_time(t)
      break if t <= time_range.begin

      expected_enqueued_ats << t
    end
    expected_enqueued_ats.reverse
  end
end
