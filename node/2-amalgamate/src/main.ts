// 2-amalgamate Node: maximally-trimmed JS using only Web APIs that llrt supports.
// No Node-specific imports, no extras — minimum surface for max minify + smallest llrt-compatible bundle.

const payload = {
  hello: "world",
  language: "node",
  uuid: crypto.randomUUID(),
  timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
};

console.log(JSON.stringify(payload));
