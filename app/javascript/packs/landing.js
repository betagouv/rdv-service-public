require("@rails/ujs").start()
require("turbolinks").start()

import { PlacesInput } from 'packs/components/places-input.js.erb';
import 'bootstrap';

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

$(document).on('turbolinks:load', function() {
  Holder.run();
  new PlacesInput(document.querySelector('.places-js-container'));
});