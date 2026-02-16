 'use client';
 
 export type LocationResult = {
   latitude: number;
   longitude: number;
 };
 
 export const getDeviceLocation = (): Promise<LocationResult> => {
   return new Promise((resolve, reject) => {
     // This universal callback will be set on the window object.
     // The Flutter host should call this function with the location data.
     // e.g., `window.handleUniversalLocationResult({ latitude: 12.34, longitude: 56.78 });`
     // or `window.handleUniversalLocationResult({ error: 'Permission denied.' });`
     (window as any).handleUniversalLocationResult = (
       location: LocationResult | { error: string }
     ) => {
       // Clean up the handler immediately to avoid memory leaks
       if ((window as any).handleUniversalLocationResult) {
           delete (window as any).handleUniversalLocationResult;
       }
 
       if (location && 'latitude' in location && 'longitude' in location) {
         resolve(location);
       } else {
         const errorMsg = (location as { error: string })?.error || 'An unknown error occurred from the host.';
         reject(new Error(errorMsg));
       }
     };
 
     // Check if the Flutter communication bridge exists
     if ((window as any).Location?.postMessage) {
       // Send a standardized message to the Flutter host, which should trigger a call to `handleUniversalLocationResult`
       (window as any).Location.postMessage('getUniversalLocation');
     } else {
       // Fallback to standard web Geolocation API
       if (navigator.geolocation) {
         navigator.geolocation.getCurrentPosition(
           (position) => {
             // Since the web API succeeded, we can call our own handler to resolve the promise.
             if ((window as any).handleUniversalLocationResult) {
                 (window as any).handleUniversalLocationResult({
                   latitude: position.coords.latitude,
                   longitude: position.coords.longitude,
                 });
             }
           },
           (error) => {
             // Since the web API failed, we can call our own handler to reject the promise.
              if ((window as any).handleUniversalLocationResult) {
                 (window as any).handleUniversalLocationResult({
                     error: error.message
                 });
             }
           },
           { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
         );
       } else {
          // If geolocation is not supported at all, reject via our handler.
          if ((window as any).handleUniversalLocationResult) {
             (window as any).handleUniversalLocationResult({
                 error: 'Geolocation is not supported by this browser.'
             });
         }
       }
     }
   });
 };