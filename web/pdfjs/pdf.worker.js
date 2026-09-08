/*! Minimal fake worker for pdf.js (for Flutter Web compatibility) */
self.onmessage = function (event) {
  console.log('pdf.worker.js loaded:', event.data);
  self.postMessage({ type: 'ready' });
};
