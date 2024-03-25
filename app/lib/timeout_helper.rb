class TimeoutHelper
  # Cette méthod permet d'appeler un callback si un block met plus de temps que `after` à s'exécuter.
  #
  # Dans tous les cas, le block passé n'est jamais interrompu.
  #
  # Exemple d'usage :
  #   TimeoutHelper.long_running_block_warn(after: 10.seconds, callback: -> { log("Le bloc a mis plus de 10 secondes à s'exécuter") }) do
  #     lancer_une_operation_longue
  #   end
  def self.long_running_block_warn(after:, callback:, &block)
    timeout_thread = Thread.new(Time.zone.now + after) do |end_time|
      Thread.pass while Time.zone.now < end_time
      callback.call
    end
    block.call
  ensure
    timeout_thread.kill
  end
end
