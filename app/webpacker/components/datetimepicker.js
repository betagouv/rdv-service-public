import 'jquery-datetimepicker/build/jquery.datetimepicker.full.min';
import 'custom-event-polyfill'
$.datetimepicker.setLocale('fr');

class Datetimepicker {

  constructor() {
    $("[data-behaviour='datepicker']").datetimepicker({
      format:'d/m/Y',
      timepicker:false,
      mask: false,
      scrollMonth: false,
      scrollInput: false,
      dayOfWeekStart: 1,
      onChangeDateTime: (_, $input) => { $input[0].dispatchEvent(new CustomEvent("change")); } // forces hooks to execute
    });
    $("[data-behaviour='datetimepicker']").datetimepicker({
      format:'d/m/Y H:i',
      mask: false,
      step: 5,
      scrollMonth: false,
      scrollInput: false,
      dayOfWeekStart: 1,
    });
    $("[data-behaviour='timepicker']").datetimepicker({
      format:'H:i',
      step: 5,
      datepicker: false,
      mask: true,
      scrollInput: false,
    });
  }
}

export { Datetimepicker };
