import http from 'k6/http';
import { sleep } from 'k6';
import { Counter } from 'k6/metrics';

// Two custom metrics to track data sent and received. We will tag data points added with the corresponding URL
// so we can filter these metrics down to see the data for individual URLs and set threshold across all or per-URL as well.
export let epDataSent = new Counter('http_data_sent');
export let epDataRecv = new Counter('http_data_received');

//**All K6 settings will be parsed here after web scraping completes.***
export let options = {
  
};

function sizeOfHeaders(hdrs) {
  return Object.keys(hdrs).reduce(
    (sum, key) => sum + key.length + hdrs[key].length,
    0,
  );
}

function trackDataMetricsPerURL(res) {
  // Add data points for sent and received data
  epDataSent.add(sizeOfHeaders(res.request.headers) + res.request.body.length, {
    url: res.url,
  });
  epDataRecv.add(sizeOfHeaders(res.headers) + res.body.length, {
    url: res.url,
  });
}

//***All URLs will be parsed here after web scraping completes.***
export default function () {
  let res;
  
  sleep(1);
}