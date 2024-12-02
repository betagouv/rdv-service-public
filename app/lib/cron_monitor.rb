class CronMonitor
  def self.expected_enqueued_count(cron_str, time_range)
    fugit_obj = Fugit.parse_cronish(cron_str)
    expected_enqueued_count = 0
    t = time_range.end
    loop do
      t = fugit_obj.previous_time(t)
      break if t <= time_range.begin

      expected_enqueued_count += 1
    end
    expected_enqueued_count
  end
end
