require("@rails/ujs").start()

// Nous souhaitons passer de Turbolinks à Turbo
// Dans un premier temps, nous ajoutons Turbo à l'application sans supprimer Turbolinks et nous désactivons le drive de Turbo.
// Cela nous permet d’utiliser les Turbo Streams et les Turbo Frames pour pouvoir supprimer l’usage des js.erb.
// Dans un second temps, nous supprimerons Turbolinks et nous activerons le drive de Turbo.
require("turbolinks").start()
import "@hotwired/turbo-rails"
Turbo.session.drive = false

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
import { planningAgentsSelect } from './components/planning-agents-select'
import { AgendaMonoAgent } from './components/calendar'
import { AgendaMultiAgent} from './components/calendar/agenda-multi-agent'
import { ParticipationSelect } from './components/rdv-user-select'
import { Tooltips } from './components/tooltips'
import { PlageOuvertureLieuSelection, PlageOuvertureSecondaryTimes } from './components/plage_ouverture.js'
import { CheckAll, UnCheckAll } from './components/check-all'
import './components/motifs_table'
import './components/browser-detection'
import './components/clear-field-on-focus.js'

import { Application } from "@hotwired/stimulus"
import CheckboxSelectAll from '@stimulus-components/checkbox-select-all'
import MotifFormController from './controllers/motif_form_controller'
import DestroyableController from './controllers/destroyable_controller'
import './controllers'

window.Stimulus = Application.start()
Stimulus.register('checkbox-select-all', CheckboxSelectAll)
Stimulus.register('motif-form', MotifFormController)
Stimulus.register('destroyable', DestroyableController)

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
  planningAgentsSelect()

  new AgendaMonoAgent()
  new AgendaMultiAgent()

  new ParticipationSelect()

  new PlageOuvertureLieuSelection()
  new PlageOuvertureSecondaryTimes()

  new CheckAll()
  new UnCheckAll()

  Tooltips()
})
