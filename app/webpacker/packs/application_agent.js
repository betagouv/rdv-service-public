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
import { PopulateLibelle } from 'components/populate-libelle';
import { ServiceFilterForMotifsSelects } from 'components/service-filter-for-motifs-selects';
import 'components/analytic.js';
import { PlacesInputs } from 'components/places-inputs.js';
import { RdvWizardStep2 } from 'components/rdv_wizard_step2.js';
import { MotifForm } from 'components/motif-form.js';
import { ZonesMap } from 'components/zones-map.js';
import { AgentsCreneaux } from 'components/agents_creneaux.js'
import { AgentUserForm } from 'components/agent-user-form.js'
import { RecordVersions } from 'components/record-versions.js'
import { RecurrenceForm } from 'components/recurrence-form.js'
import { MergeUsersForm } from 'components/merge-users-form.js'
import { SectorAttributionForm } from 'components/sector-attribution-form.js'
import { ZoneForm } from 'components/zone-form.js'
import { Select2Inputs } from 'components/select2-inputs';
import { RdvStatusDropdowns } from 'components/rdv-status-dropdowns'
import 'components/calendar';
import 'components/tooltip';
import 'components/sentry';
import 'components/browser-detection';

import 'stylesheets/print';
import 'stylesheets/application_agent'

// this is necessary so images are compiled by webpack
require.context('../images', true)

$.fn.select2.defaults.set("theme", "bootstrap4");
$.fn.select2.defaults.set("language", "fr");

new Modal();
new Rightbar();
new Select2Inputs();
new ServiceFilterForMotifsSelects();

global.$ = require('jquery');

$(document).on('shown.bs.modal', '.modal', function(e) {
  $('input[type="tel"]').mask('00 00 00 00 00')
  new Datetimepicker();
  new AgentUserForm();
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
  new PlacesInputs();
  new Datetimepicker();
  $(".tooltip").tooltip("hide");
  new RecurrenceForm();
});

$(document).on('hide.bs.modal', '.modal', function(e) {
  $('.modal-backdrop').remove();
  $("[data-behaviour='datepicker'], [data-behaviour='datetimepicker'], [data-behaviour='timepicker']").datetimepicker('destroy');
});

$(document).on('show.bs.modal', '.modal', function(e) {
  new PlacesInputs();
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

  new PlacesInputs();

  new PopulateLibelle();

  new Datetimepicker();

  new MotifForm();

  new RdvWizardStep2();

  new ZonesMap();

  new AgentsCreneaux();

  new AgentUserForm();

  new RecordVersions();

  new RecurrenceForm();

  new MergeUsersForm();

  new SectorAttributionForm();

  new ZoneForm();

  new RdvStatusDropdowns();
});
