
// UMD (Universal Module Definition) boilerplate to make the function available globally.
(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    // Node. Does not work with strict CommonJS, but
    // only CommonJS-like environments that support module.exports,
    // like Node.
    module.exports = factory();
  } else {
    // Browser globals (root is window)
    root.getDeviceLocation = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {

  // This is the core function.
  return function getDeviceLocation() {
    return new Promise((resolve, reject) => {
      // This universal callback will be set on the window object.
      // The Flutter host should call this function with the location data.
      window.handleUniversalLocationResult = (location) => {
        // Clean up the handler immediately to avoid memory leaks.
        if (window.handleUniversalLocationResult) {
          delete window.handleUniversalLocationResult;
        }

        if (location && location.latitude !== undefined && location.longitude !== undefined) {
          resolve(location);
        } else {
          const errorMsg = location?.error || 'An unknown error occurred from the host.';
          reject(new Error(errorMsg));
        }
      };

      // Check if a specific Flutter communication bridge exists.
      // This is a common pattern for Flutter web to communicate with JS.
      if (window.Location?.postMessage) {
        // Send a standardized message to the Flutter host.
        window.Location.postMessage('getUniversalLocation');
      }
      // Fallback to standard web Geolocation API if the bridge isn't available.
      else if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            // If the web API succeeds, we call our own handler to resolve the promise.
            if (window.handleUniversalLocationResult) {
              window.handleUniversalLocationResult({
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
              });
            }
          },
          (error) => {
            // If the web API fails, we call our handler to reject the promise.
            if (window.handleUniversalLocationResult) {
              window.handleUniversalLocationResult({
                error: error.message
              });
            }
          },
          { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
        );
      } else {
        // If geolocation is not supported at all, reject via our handler.
        if (window.handleUniversalLocationResult) {
          window.handleUniversalLocationResult({
            error: 'Geolocation is not supported by this browser.'
          });
        }
      }
    });
  };
}));
