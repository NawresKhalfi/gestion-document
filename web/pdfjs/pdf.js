/*! pdf.js simplified loader for Flutter Web */
if (!window['pdfjsLib']) {
  window['pdfjsLib'] = {};
}

window['pdfjsLib'].GlobalWorkerOptions = {
  workerSrc: './pdfjs/pdf.worker.js',
};

window['pdfjsLib'].getDocument = function (url) {
  return fetch(url)
    .then((response) => response.arrayBuffer())
    .then((data) => ({
      promise: Promise.resolve({
        numPages: 1,
        getPage: async (pageNum) => ({
          render: () => ({
            promise: Promise.resolve('Rendered'),
          }),
        }),
      }),
    }));
};
