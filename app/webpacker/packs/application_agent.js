import 'core-js/stable'
import "regenerator-runtime/runtime"; // cf https://github.com/rails/webpacker#usage
require("@rails/ujs").start()
require("turbolinks").start()
require("chartkick")
require("chart.js")
import 'bootstrap';
import 'moment/moment.js';
import 'jquery-mask-plugin';
import 'moment/locale/fr.js';
import 'holderjs/holder.min';
import 'jquery-slimscroll/jquery.slimscroll';
import 'metismenu/dist/metisMenu.min';
import 'select2/dist/js/select2.full.min.js';
import 'select2/dist/js/i18n/fr.js';
import { Datetimepicker } from 'components/datetimepicker';
import { Avatar } from 'components/avatar';
import { Menu } from 'components/menu';
import { Layout } from 'components/layout';
import { Modal } from 'components/modal';
import { Rightbar } from 'components/rightbar';
import { InviteUserOnCreate } from 'components/invite-user-on-create';
import { PopulateLibelle } from 'components/populate-libelle';
import 'components/analytic.js';
import { PlacesInput } from 'components/places-input.js';
import { ShowHidePassword } from 'components/show-hide-password.js';
import { RdvWizardStep2 } from 'components/rdv_wizard_step2.js';
import { MotifForm } from 'components/motif-form.js';
import { ZonesMap } from 'components/zones-map.js';
import 'components/calendar';
import 'components/select2';
import 'components/tooltip';
import 'components/sentry';
import 'components/browser-detection';
import "actiontext";
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

import 'stylesheets/print';
import 'stylesheets/application_agent'

// this is necessary so images are compiled by webpack
require.context('../images', true)

const application = Application.start();
const context = require.context("./controllers", true, /\.js$/);
application.load(definitionsFromContext(context));

new Modal();
new Rightbar();

global.$ = require('jquery');

$(document).on('shown.bs.modal', '.modal', function(e) {
  $('input[type="tel"]').mask('00 00 00 00 00')
  new Datetimepicker();
  new InviteUserOnCreate();
});

$(document).on('shown.rightbar', '.right-bar', function(e) {
  $('input[type="tel"]').mask('00 00 00 00 00')
  $('.right-bar .slimscroll-menu').slimscroll({
    height: 'auto',
    position: 'right',
    size: "8px",
    color: '#9ea5ab',
    wheelStep: 5,
    touchScrollStep: 20
  });
  new PlacesInput(document.querySelector('.places-js-container'));
  $( ".select2-input").select2({
    theme: "bootstrap4"
  });
  new Datetimepicker();
  $(".tooltip").tooltip("hide");
});

$(document).on('hide.bs.modal', '.modal', function(e) {
  $('.modal-backdrop').remove();
  $("[data-behaviour='datepicker'], [data-behaviour='datetimepicker'], [data-behaviour='timepicker']").datetimepicker('destroy');
});

$(document).on('show.bs.modal', '.modal', function(e) {
  new PlacesInput(document.querySelector('.places-js-container'));
});

$(document).on('turbolinks:load', function() {
  Holder.run();

  let menu = new Menu();
  let layout = new Layout();

  layout.init();
  menu.init();
  new Avatar().init();

  $('input[type="tel"]').mask('00 00 00 00 00')
  $(window).on('resize', function(e) {
    e.preventDefault();
    layout.init();
    menu.resetSidebarScroll();
  });

  new PlacesInput(document.querySelector('.places-js-container'));

  new PopulateLibelle();

  new Datetimepicker();

  new InviteUserOnCreate();

  new ShowHidePassword();

  new MotifForm();

  new RdvWizardStep2();

  new ZonesMap();
});
