(function () {
  let kakaoMapsPromise = null;

  function loadKakao(appKey) {
    if (!appKey) {
      return Promise.reject(new Error('Kakao map key is missing.'));
    }
    if (window.kakao && window.kakao.maps) {
      return Promise.resolve(window.kakao.maps);
    }
    if (kakaoMapsPromise) return kakaoMapsPromise;

    kakaoMapsPromise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src =
        'https://dapi.kakao.com/v2/maps/sdk.js?autoload=false&libraries=services&appkey=' +
        encodeURIComponent(appKey);
      script.async = true;
      script.onload = () => {
        if (!window.kakao || !window.kakao.maps) {
          reject(new Error('Kakao SDK loaded, but maps object is unavailable.'));
          return;
        }
        window.kakao.maps.load(() => resolve(window.kakao.maps));
      };
      script.onerror = () =>
        reject(
          new Error(
            'Kakao Maps SDK could not load. Check the JavaScript key and Web platform domain.'
          )
        );
      document.head.appendChild(script);
    });

    return kakaoMapsPromise;
  }

  function setStatus(container, message) {
    container.innerHTML = '';
    const box = document.createElement('div');
    box.style.cssText =
      'height:100%;display:flex;align-items:center;justify-content:center;padding:18px;text-align:center;background:#f0f0ec;color:#37503d;font:700 14px system-ui;border-radius:24px;';
    box.textContent = message;
    container.appendChild(box);
  }

  function render(containerId, options) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const lat = Number(options.lat);
    const lng = Number(options.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      setStatus(container, 'Destination coordinates are unavailable.');
      return;
    }

    setStatus(container, 'Loading Kakao Map...');
    loadKakao(options.appKey)
      .then((maps) => {
        container.innerHTML = '';
        const center = new maps.LatLng(lat, lng);
        const map = new maps.Map(container, {
          center,
          level: Number(options.level || 6),
        });

        const destinationMarker = new maps.Marker({ position: center });
        destinationMarker.setMap(map);
        const info = new maps.InfoWindow({
          content:
            '<div style="padding:8px 12px;font-size:13px;font-weight:700;color:#263229;white-space:nowrap;">' +
            String(options.nameKo || options.name || 'Destination') +
            '</div>',
        });
        info.open(map, destinationMarker);

        if (navigator.geolocation && options.showRoute) {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              const start = new maps.LatLng(
                position.coords.latitude,
                position.coords.longitude
              );
              const startMarker = new maps.Marker({ position: start });
              startMarker.setMap(map);
              const bounds = new maps.LatLngBounds();
              bounds.extend(start);
              bounds.extend(center);
              map.setBounds(bounds, 32, 32, 32, 32);
              new maps.Polyline({
                map,
                path: [start, center],
                strokeWeight: 5,
                strokeColor: '#37503d',
                strokeOpacity: 0.82,
                strokeStyle: 'solid',
              });
            },
            () => map.setCenter(center),
            { enableHighAccuracy: true, timeout: 6500, maximumAge: 60000 }
          );
        } else {
          map.setCenter(center);
        }
      })
      .catch((error) => {
        setStatus(container, error.message || 'Kakao Map is unavailable.');
      });
  }

  window.JejuFlowKakaoMap = { render };
})();
