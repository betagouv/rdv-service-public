const MAP_COLORS = {
  'RDV Solidarités': '#f983f1',
  'RDV Service Public': '#5fe0eb',
  'Mairie': '#2e4177',
  'Autre': '#e55e5e',
}

const initMap = (mapElt, lieux) => {
  const map = new maplibregl.Map({
    container: mapElt,
    style: 'https://openmaptiles.data.gouv.fr/styles/positron/style.json',
    bounds: [[-5.3, 41.3], [9.8, 51.1]], // France métropolitaine
    fitBoundsOptions: { padding: 20 },
  })

  map.on('load', () => {
    map.addControl(new maplibregl.NavigationControl());

    map.addSource('lieux', {
      type: "geojson",
      data: {
        "type": "FeatureCollection",
        "features": lieux.map((lieu) => ({
          "type": "Feature",
          "properties": lieu,
          "geometry": {
            "type": "Point",
            "coordinates": [lieu.longitude, lieu.latitude]
          }
        }))
      }
    })

    map.addLayer({
      id: 'lieux-markers',
      type: 'circle',
      source: 'lieux',
      paint: {
        'circle-color': [
          'match',
          ['get', 'type_organisation'],
          'RDV Solidarités', MAP_COLORS['RDV Solidarités'],
          'RDV Service Public', MAP_COLORS['RDV Service Public'],
          'Mairie', MAP_COLORS['Mairie'],
          MAP_COLORS['Autre']
        ],
        'circle-radius': 4,
        'circle-stroke-width': 1,
        'circle-stroke-color': '#fff'
      }
    });

    map.on('click', 'lieux-markers', (e) => {
      const coordinates = e.features[0].geometry.coordinates.slice();
      const { organisation_name, type_organisation } = e.features[0].properties;
      new maplibregl.Popup()
        .setLngLat(coordinates)
        .setHTML(`${organisation_name} - ${type_organisation}`)
        .addTo(map);
    });

    map.on('mouseenter', 'lieux-markers', () => {
      map.getCanvas().style.cursor = 'pointer';
    });

    map.on('mouseleave', 'lieux-markers', () => {
      map.getCanvas().style.cursor = '';
    });
  })

  return map
}

const setCounters = (lieux) => {
  const counts = lieux.reduce((acc, { type_organisation }) => {
    acc[type_organisation] = (acc[type_organisation] || 0) + 1;
    return acc;
  }, {});

  for (const [counterName, count] of Object.entries(counts)) {
    const counterElt = document.querySelector(`[data-target="map-counter"][data-group="${counterName}"]`)
    if (counterElt) counterElt.textContent = `(${count})`
  }
}

const displayLegendCircles = () => {
  // on préfère définir les couleurs depuis le JS plutôt que dans le CSS pour qu’elles soient définies à un seul endroit
  Object.entries(MAP_COLORS).forEach(([group, color]) => {
    const circleElt = document.querySelector(`[data-target="map-legend-circle"][data-group="${group}"]`)
    if (circleElt) circleElt.style.backgroundColor = color
  })
}

const moveHandler = (e, map) => {
  const region = e.currentTarget.dataset.region
  const bounds = {
    "guadeloupe": [[-61.8, 15.8], [-60.9, 16.5]],
    "martinique": [[-61.3, 14.3], [-60.8, 14.9]],
    "guyane": [[-54.7, 2.1], [-51.6, 5.1]],
    "la-reunion": [[55.1, -21.6], [55.8, -20.7]],
    "mayotte": [[44.9, -13.1], [45.4, -12.6]],
  }[region]
  if (bounds) map.fitBounds(bounds, { padding: 20 })
}

const initMoveHandlers = (map) => {
  document
    .querySelectorAll('[data-action="click->stats-map#move"]')
    .forEach(elt => elt.addEventListener('click', e => moveHandler(e, map)))
}

window.addEventListener("load", () => {
  const mapElt = document.querySelector('[data-controller="stats-map"]')
  if (!mapElt) return

  fetch(mapElt.dataset.url)
    .then(response => {
      if (response.ok) return response.json();
      throw new Error(`HTTP status ${response.status}`);
    })
    .then(lieux => {
      const map = initMap(mapElt, lieux)
      displayLegendCircles()
      setCounters(lieux)
      initMoveHandlers(map)
    })
    .catch(error => {
      console.error(error)
      mapElt.textContent = "⚠️ Erreur lors du chargement de la carte"
    })
})
