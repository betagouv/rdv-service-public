import 'jquery-datetimepicker/build/jquery.datetimepicker.full.min';
$.datetimepicker.setLocale('fr');

class Datetimepicker {

  constructor() {
    $("[data-behaviour='datepicker']").datetimepicker({
      format:'d/m/Y',
      timepicker:false,
      mask: true,
    });
    $("[data-behaviour='datetimepicker']").datetimepicker({
      format:'d/m/Y H:i',
      mask: false,
      step: 5,
    });
    $("[data-behaviour='timepicker']").datetimepicker({
      format:'H:i',
      step: 5,
      datepicker: false,
      mask: true,
    });
  }
}

export { Datetimepicker };