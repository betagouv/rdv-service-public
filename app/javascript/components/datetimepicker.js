import 'jquery-datetimepicker/build/jquery.datetimepicker.full.min';
import 'custom-event-polyfill'
$.datetimepicker.setLocale('fr');

class Datetimepicker {

  constructor() {
    document.querySelectorAll("[data-behaviour='datepicker']").forEach(input => {
      $(input).datetimepicker({
        format:'d/m/Y',
        timepicker:false,
        mask: true,
        scrollMonth: false,
        scrollInput: false,
        dayOfWeekStart: 1,
        onChangeDateTime: (_, $input) => { $input[0].dispatchEvent(new CustomEvent("change")); }, // forces hooks to execute
        ...input.dataset,
      });
    });

    document.querySelectorAll("[data-behaviour='datetimepicker']").forEach(input => {
      $(input).datetimepicker({
        format:'d/m/Y H:i',
        mask: false,
        step: 5,
        scrollMonth: false,
        scrollInput: false,
        dayOfWeekStart: 1,
        ...input.dataset,
      });
    });

    document.querySelectorAll("[data-behaviour='timepicker']").forEach(input => {
      $(input).datetimepicker({
        format:'H:i',
        step: 5,
        datepicker: false,
        mask: true,
        scrollInput: false,
        ...input.dataset,
      });
    });
  }
}

export { Datetimepicker };
