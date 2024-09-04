class ZonesMap {

  constructor() {
    this.mapElement = document.querySelector('#js-zones-map')
    if (!this.mapElement) return

    this.hoveredCityElt = document.querySelector("#js-hovered-city")
    this.getCenterCoordinates()
  }

  getCenterCoordinates = () => {
    const url = "https://api-adresse.data.gouv.fr/search/"
    const searchParams = new URLSearchParams()
    searchParams.append("q", this.mapElement.dataset.centerQuery)
    searchParams.append("type", "municipality")
    searchParams.append("limit", "1")
    fetch(`${url}?${searchParams}`).
      then(res => res.json()).
      then(data => {
        if (data.features.length > 0)
          this.initMap(data.features[0].geometry.coordinates, 8)
        else
          this.initMap([1.7191036, 46.71109], 4)
      })
  }

  initMap = (centerCoordinates, zoom) => {
    var map = new mapboxgl.Map({
      container: 'js-zones-map',
      hash: true,
      center: centerCoordinates,
      zoom: zoom,
      minZoom: 1,
      style: {
        version: 8,
        sources: {
          'communes-tiles': {
            type: 'vector',
            url: 'https://etalab-tiles.fr/data/decoupage-administratif.json'
          }
        },
        layers: []
      }
    });
    map.addControl(new mapboxgl.NavigationControl());

    map.on('load', () => {
      map.addLayer({
        'id': 'departements-contour',
        'type': 'line',
        'source': 'communes-tiles',
        'source-layer': 'departements',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#ccc',
          'line-width': 1
        }
      });
      map.addLayer({
        'id': 'communes-fill',
        'type': 'fill',
        'source': 'communes-tiles',
        'source-layer': 'communes',
        'paint': {
          'fill-color': [
            'match',
            ['get', 'code'],
          ].concat(this.getMatchingValues()).
            concat('transparent'),
        }
      });
      map.addLayer({
        'id': 'communes-contour',
        'type': 'line',
        'source': 'communes-tiles',
        'source-layer': 'communes',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#ccc',
          'line-width': 1
        }
      });

      // tried but could not get popup to work
      // cf https://docs.mapbox.com/mapbox-gl-js/example/popup-on-hover/
      map.on('mousemove', e => {
        const cityFeature = map.queryRenderedFeatures(e.point).filter(f => f.layer.id == 'communes-fill')[0]
        if (!cityFeature) return;

        const { code, nom } = cityFeature.properties
        this.hoveredCityElt.innerHTML = `${nom}, ${code}`
      })
    })
  }

  getMatchingValues = () => {
    let cases = []
    document.querySelectorAll(".js-legend-organisation").forEach(elt => {
      const cityCodes = JSON.parse(elt.dataset.cityCodesJson).colors
      const color = elt.dataset.color
      cityCodes.forEach(code => {
        if (cases.indexOf(code) == -1) cases = cases.concat([code, color])
      })
    })
    return cases;
  }
}

export { ZonesMap }
