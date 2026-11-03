# prio haute utilisée pour les codes de connexion
class HighPriorityMailerDeliveryJob < ApplicationMailerDeliveryJob
  self.priority = -100 # plus c'est petit plus c'est prioritaire, le défaut est 0
end
