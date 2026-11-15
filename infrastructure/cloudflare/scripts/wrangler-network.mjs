// Limit publishing connections on constrained local networks. This preloads only
// the CLI process; it is not bundled into the public Worker or Flutter assets.
import { Agent, setGlobalDispatcher } from "undici";

setGlobalDispatcher(new Agent({
  connections: 3,
  connect: { timeout: 60000, rejectUnauthorized: true },
  headersTimeout: 120000,
  bodyTimeout: 120000,
}));
