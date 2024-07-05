require("@rails/ujs").start()
require("turbolinks").start()
import 'bootstrap'
import 'select2/dist/js/select2.full.min.js'
import 'select2/dist/js/i18n/fr.js'
import { Datetimepicker } from './components/datetimepicker'
import { Menu } from './components/menu'
import { Modal } from './components/modal'
import { ServiceFilterForMotifsSelects } from './components/service-filter-for-motifs-selects'
import { SubmitOnChange } from './components/submit-on-change'
import { PlacesInputs } from './components/places-inputs.js'
import { RdvWizardStep2 } from './components/rdv_wizard_step2.js'
import { RdvLieu } from './components/rdv_lieu.js'
import { PastDateAlert } from './components/past-date-alert.js'
import { Clipboard } from './components/clipboard.js'
import { ZonesMap } from './components/zones-map.js'
import { AgentUserForm } from './components/agent-user-form.js'
import { AgentRoleForm } from './components/agent-role-form.js'
import { RecurrenceForm } from './components/recurrence-form.js'
import { MergeUsersForm } from './components/merge-users-form.js'
import { SectorAttributionForm } from './components/sector-attribution-form.js'
import { ZoneForm } from './components/zone-form.js'
import { Select2Inputs } from './components/select2-inputs'
import { PlanningAgentSelect } from './components/planning-agent-select'
import { ParticipationSelect } from './components/rdv-user-select'
import { DestroyButton } from './components/destroy-button'
import { Tooltips } from './components/tooltips'
import { PlageOuverture } from './components/plage_ouverture.js'
import './components/calendar'
import './components/browser-detection'
import './components/clear-field-on-focus.js'

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

window.Stimulus = Application.start()
const context = require.context("./controllers", true, /\.js$/)
Stimulus.load(definitionsFromContext(context))

import './stylesheets/print'
import './stylesheets/application_agent'

$.fn.select2.defaults.set("theme", "bootstrap4")
$.fn.select2.defaults.set("language", "fr")

new Modal()
new Select2Inputs()
new ServiceFilterForMotifsSelects()

global.$ = require('jquery')

$(document).on('shown.bs.modal', '.modal', function(e) {
  new Datetimepicker()
  new AgentUserForm()
})

$(document).on('hide.bs.modal', '.modal', function(e) {
  $('.modal-backdrop').remove()
  $("[data-behaviour='datepicker'], [data-behaviour='datetimepicker'], [data-behaviour='timepicker']").datetimepicker('destroy')
})

$(document).on('show.bs.modal', '.modal', function(e) {
  new PlacesInputs()
})

$(document).on('turbolinks:load', function() {
  let menu = new Menu()

  menu.init()

  $(window).on('resize', function(e) {
    e.preventDefault()
  })

  new PlacesInputs()

  new Datetimepicker()

  new SubmitOnChange()

  new RdvWizardStep2()

  new RdvLieu()

  new PastDateAlert()

  new Clipboard()

  new ZonesMap()

  new AgentUserForm()

  new AgentRoleForm()

  new RecurrenceForm()

  new MergeUsersForm()

  new SectorAttributionForm()

  new ZoneForm()

  new PlanningAgentSelect()

  new ParticipationSelect()

  new DestroyButton()

  new PlageOuverture()

  Tooltips()
})
