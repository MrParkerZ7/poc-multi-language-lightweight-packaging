import { v4 as uuidv4 } from "uuid";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc.js";

// Same enterprise dep set as 0-standard / esbuild / ncc / webpack so the
// bun-compile binary size reflects bundling the same code, not a slimmer source.
import axios from "axios";  // eslint-disable-line @typescript-eslint/no-unused-vars
import { z } from "zod";    // eslint-disable-line @typescript-eslint/no-unused-vars

dayjs.extend(utc);

const payload = {
  hello: "world",
  language: "node",
  uuid: uuidv4(),
  timestamp: dayjs.utc().format("YYYY-MM-DDTHH:mm:ss[Z]"),
};

console.log(JSON.stringify(payload));
