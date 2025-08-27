import "chartkick/chart.js"

document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll(".js-column-chart").forEach((chartElement, i) =>{
    chartElement.id = `column-chart-${i}`
    new Chartkick.ColumnChart(chartElement.id, chartElement.dataset.path, JSON.parse(chartElement.dataset.options))
  })
})
