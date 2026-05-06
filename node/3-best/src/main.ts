// 3-best Node: QuickJS-NG-compatible. No `crypto.randomUUID` (not in QuickJS-NG yet),
// no `Date.toISOString` reliance — manually format. Pure-ECMAScript, no host APIs.

function uuidv4(): string {
  // Math.random-based UUIDv4 — not cryptographically secure but valid format.
  // Acceptable for the POC; production should use a host-provided RNG.
  const hex = "0123456789abcdef";
  let s = "";
  for (let i = 0; i < 36; i++) {
    if (i === 8 || i === 13 || i === 18 || i === 23) {
      s += "-";
    } else if (i === 14) {
      s += "4";
    } else if (i === 19) {
      s += hex[(Math.random() * 4) | 8];
    } else {
      s += hex[(Math.random() * 16) | 0];
    }
  }
  return s;
}

function isoTimestamp(): string {
  const d = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}T${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}:${pad(d.getUTCSeconds())}Z`;
}

const payload = {
  hello: "world",
  language: "node",
  uuid: uuidv4(),
  timestamp: isoTimestamp(),
};

console.log(JSON.stringify(payload));
