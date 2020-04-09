import flatpickr from 'flatpickr'
import { French } from 'flatpickr/dist/l10n/fr.js'

function bindDateTimePickers() {
  [...document.querySelectorAll('[data-type="time"]')].forEach((time) => {
    flatpickr(time, {
      locale: French,
      enableTime: true,
      enableSeconds: true,
      noCalendar: true,
      altInput: true,
      altFormat: ' h:i:S K',
      dateFormat: 'H:i:S' // H:i
    })
  });

  [...document.querySelectorAll('[data-type="datetime"]')].forEach((time) => {
    flatpickr(time, {
      locale: French,
      enableTime: true,
      altInput: true,
      altFormat: 'F J (D), Y - h:i:S K',
      dateFormat: 'Z' // Y-m-d H:i
    })
  })
}

document.addEventListener("turbolinks:load", function () {
  bindDateTimePickers()
})
