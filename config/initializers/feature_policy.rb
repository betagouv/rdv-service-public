Rails.application.config.feature_policy do |f|
  f.camera      :none
  f.gyroscope   :none
  f.microphone  :none
  f.usb         :none
  f.fullscreen  :none
  f.geolocation :self
  f.payment     :none
end
