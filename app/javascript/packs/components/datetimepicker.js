class Datetimepicker {

  constructor() {
    $('[data-behavior=datetimepicker]').daterangepicker({
      opens: 'right',
      singleDatePicker: true,
      autoUpdateInput: true,
      timePicker: true,
      timePicker24Hour: true,
      timePickerIncrement: 5,
      startDate: moment(),
      locale: { 
        format: 'DD/MM/YYYY - hh:mm',
        cancelLabel: 'Annuler',
        applyLabel: 'OK',
      } 
    });
    $('[data-behavior=datetimepicker]').on('apply.daterangepicker', function(ev, picker) {
      $(this).val(picker.startDate.format('DD/MM/YYYY - HH:mm'));
    });
    $('[data-behavior=datetimepicker]').on('cancel.daterangepicker', function(){
      $(this).val(' ');
    });
  }
}

export { Datetimepicker };