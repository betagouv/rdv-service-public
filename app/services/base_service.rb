class BaseService
  def self.count_time
    @total_time ||= 0
    res = nil
    @total_time += Benchmark.measure { res = yield }.to_a.last
    res
  end

  def self.total_time
    @total_time
  end

  def self.reset_time
    @total_time = 0
  end

  def self.perform_with(*args, **kwargs)
    new(*args, **kwargs).perform
  end
end
