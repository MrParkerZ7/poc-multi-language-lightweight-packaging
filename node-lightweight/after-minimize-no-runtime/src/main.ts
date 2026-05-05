// llrt (AWS Low Latency Runtime) supports a subset of Node APIs.
// Avoid Node-specific globals; use Web Crypto for UUID and `Date` for timestamp.

const payload = {
  hello: "world",
  language: "node",
  uuid: crypto.randomUUID(),
  timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
};

console.log(JSON.stringify(payload));
