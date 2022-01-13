import 'core-js/stable'
import "regenerator-runtime/runtime"; // cf https://github.com/rails/webpacker#usage
require("@rails/ujs").start()
require("turbolinks").start()
require("chartkick")
require("chart.js")
import 'bootstrap';
import 'moment/moment.js';
import 'moment/locale/fr.js';
import 'holderjs/holder.min';
import 'select2/dist/js/select2.full.min.js';
import 'select2/dist/js/i18n/fr.js';
import { Datetimepicker } from 'components/datetimepicker';
import { Menu } from 'components/menu';
import { Modal } from 'components/modal';
import { ServiceFilterForMotifsSelects } from 'components/service-filter-for-motifs-selects';
import { MotifFilters } from 'components/motif-filters';
import 'components/analytic.js';
import { PlacesInputs } from 'components/places-inputs.js';
import { RdvWizardStep2 } from 'components/rdv_wizard_step2.js';
import { MotifForm } from 'components/motif-form.js';
import { ZonesMap } from 'components/zones-map.js';
import { AgentUserForm } from 'components/agent-user-form.js'
import { RecurrenceForm } from 'components/recurrence-form.js'
import { MergeUsersForm } from 'components/merge-users-form.js'
import { SectorAttributionForm } from 'components/sector-attribution-form.js'
import { ZoneForm } from 'components/zone-form.js'
import { Select2Inputs } from 'components/select2-inputs';
import { PlanningAgentSelect } from 'components/planning-agent-select';
import { RdvUserSelect } from 'components/rdv-user-select';
import { DestroyButton } from 'components/destroy-button';
import 'components/copytoclipboard';
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
new Select2Inputs();
new ServiceFilterForMotifsSelects();

global.$ = require('jquery');

$(document).on('shown.bs.modal', '.modal', function(e) {
  new Datetimepicker();
  new AgentUserForm();
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

  menu.init();

  $(window).on('resize', function(e) {
    e.preventDefault();
  });

  new PlacesInputs();

  new Datetimepicker();

  new MotifForm();

  new MotifFilters();

  new RdvWizardStep2();

  new ZonesMap();

  new AgentUserForm();

  new RecurrenceForm();

  new MergeUsersForm();

  new SectorAttributionForm();

  new ZoneForm();

  new PlanningAgentSelect();

  new RdvUserSelect();

  new DestroyButton();
});
