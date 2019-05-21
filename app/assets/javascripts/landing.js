//= require rails-ujs
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require turbolinks
//= require holder
//= require_tree ./async

$(function() {
  $('.link-scroll').on('click', function(e) {
    const anchor = $(this);
    $('html, body').stop().animate({ scrollTop: $(anchor.attr('href')).offset().top }, 1000);
    e.preventDefault();
  });
 
  $('body').scrollspy({
    target: '#navbarSupportedContent',
    offset: 80
  });

  $('.navbar .navbar-toggler').on('click', function() {
    $(this).toggleClass('active');
  });
});
