import "chartkick/chart.js"

// Cette fonction est un remplacement de la gem chartkick, qui n'était pas compatible avec nos CSP restreintes.
document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll(".js-column-chart").forEach((chartElement, i) =>{
    chartElement.id = `column-chart-${i}`
    new Chartkick.ColumnChart(chartElement.id, chartElement.dataset.path, JSON.parse(chartElement.dataset.options))
  })
})
