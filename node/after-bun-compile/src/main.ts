import { v4 as uuidv4 } from "uuid";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc.js";

dayjs.extend(utc);

const payload = {
  hello: "world",
  language: "node",
  uuid: uuidv4(),
  timestamp: dayjs.utc().format("YYYY-MM-DDTHH:mm:ss[Z]"),
};

console.log(JSON.stringify(payload));
