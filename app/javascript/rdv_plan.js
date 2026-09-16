import { Application } from "@hotwired/stimulus"
import RdvPlanController from './controllers/rdv_plan_controller'

window.Stimulus = Application.start()
Stimulus.register('rdv-plan', RdvPlanController)

// Il est nécessaire d'importer le CSS après le JS pour
// que nos customisations FullCalendar fonctionnent.
import './stylesheets/rdv_plan';
