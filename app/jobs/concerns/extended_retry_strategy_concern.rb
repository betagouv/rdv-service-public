module ExtendedRetryStrategyConcern
  extend ActiveSupport::Concern

  included do
    # This retry_on means:
    # "retry 20 times with an exponential backoff, then mark job as discarded"
    #
    # Exponential backoff is n^4, so wait times between retries will be as follows:
    # attempt:  1   2    3    4   5    6    7    8     9     10    11   12   13  14     15   16     17     18   19     20
    # backoff:  1s, 16s, 81s, 4m, 10m, 21m, 40m, 68m,  109m, 166m, 4h,  6h,  8h, 11h,   14h, 18h,   23h,   29h, 36h,   44h
    # total:    1s, 17s, 98s, 6m, 16m, 38m, 78m, 146m ,4h,   7h,   11h, 16h, 1d, 1d11h, 2d,  2d19h, 3d18h, 5d,  6d12h, 8d8h
    # sum: (1..20).map { _1 ** 4 }.sum.to_f / 60 / 60 / 24 ~= 8 days
    # it therefore takes more than 8 days for a job to be discarded
    retry_on(StandardError, wait: :polynomially_longer, attempts: 20, priority: DefaultJobBehaviour::PRIORITY_OF_RETRIES)
  end
end
