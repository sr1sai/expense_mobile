const fs = require("fs");
const os = require("os");

const FILE = "./assets/env.development.json";
const PORT = 5230;

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const iface of Object.values(interfaces)) {
    for (const details of iface) {
      if (details.family === "IPv4" && !details.internal) {
        return details.address;
      }
    }
  }
  throw new Error("No local IP found");
}

const ip = getLocalIP();

let config = {};
if (fs.existsSync(FILE)) {
  try {
    config = JSON.parse(fs.readFileSync(FILE, "utf8"));
  } catch (e) {
    console.error(`Failed to parse ${FILE}, recreating. Error:`, e.message);
    config = {};
  }
} else {
  // ensure directory exists
  const dir = FILE.substring(0, FILE.lastIndexOf("/"));
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

config.BASE_URL = `http://${ip}:${PORT}`;

fs.writeFileSync(FILE, JSON.stringify(config, null, 2));

console.log(`BASE_URL updated to ${config.BASE_URL}`);
