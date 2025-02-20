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
}

const setCounters = (lieux) => {
  const counts = lieux.reduce((acc, { type_organisation }) => {
    acc[type_organisation] = (acc[type_organisation] || 0) + 1;
    return acc;
  }, {});

  for (const [counterName, count] of Object.entries(counts)) {
    const counterElt = document.querySelector(`[data-target="map-counter"][data-counter-name="${counterName}"]`)
    if (counterElt) counterElt.textContent = `(${count})`
  }
}

const displayLegendCircles = () => {
  Object.entries(MAP_COLORS).forEach(([group, color]) => {
    const circleElt = document.querySelector(`[data-target="map-legend-circle"][data-group="${group}"]`)
    if (circleElt) circleElt.style.backgroundColor = color
  })
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
      initMap(mapElt, lieux)
      displayLegendCircles()
      setCounters(lieux)
    })
    .catch(error => {
      console.error(error)
      mapElt.textContent = "⚠️ Erreur lors du chargement de la carte"
    })
})
