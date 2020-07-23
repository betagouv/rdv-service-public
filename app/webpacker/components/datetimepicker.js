import 'jquery-datetimepicker/build/jquery.datetimepicker.full.min';
$.datetimepicker.setLocale('fr');

class Datetimepicker {

  constructor() {
    $("[data-behaviour='datepicker']").datetimepicker({
      format:'d/m/Y',
      timepicker:false,
      mask: true,
      scrollMonth: false,
      scrollInput: false,
      onChangeDateTime: (_, $input) => { $input[0].dispatchEvent(new Event("change")); } // forces stimulus actions to execute
    });
    $("[data-behaviour='datetimepicker']").datetimepicker({
      format:'d/m/Y H:i',
      mask: false,
      step: 5,
      scrollMonth: false,
      scrollInput: false,
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
