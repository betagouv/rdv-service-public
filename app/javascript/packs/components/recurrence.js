document.addEventListener('turbolinks:load', function() {
  var source = $('#recurrence-source');
  var target = $('#recurrence-target');

  source.on('change', function(e){
    var dayOfWeek = moment(source.val()).format('dddd');
    target.find("#weekly").first().html(`Toutes les semaines le ${dayOfWeek}`)
    target.find("#weekly_by_2").first().html(`Toutes les 2 semaines le ${dayOfWeek}`)
  });
});
