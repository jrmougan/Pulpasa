import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
const proj = process.argv[2];
const c = new Client({name:"pulpasa-probe",version:"0"});
await c.connect(new StdioClientTransport({ command: "npx", args: ["-y","godot-mcp-runtime@4.0.1"], env: {...process.env, GODOT_MCP_DISABLE_ELICITATION:"true"} }));
let fail=0; const call = async (name, args) => { const r = await c.callTool({name, arguments: args}, undefined, {timeout:120000}); fail |= !!r.isError;
  console.log(`--- ${name} isError=${!!r.isError}\n` + r.content.filter(x=>x.type==="text").map(x=>x.text).join("\n").slice(0,1200)); return r; };
try {
  await call("run_project", {projectPath: proj, scene: "scenes/levels/level_01.tscn", background: true});
  await new Promise(r=>setTimeout(r,4000));
  await call("simulate_input", {actions:[{type:"action", action:"p1_move_left", hold_ms:500},{type:"action", action:"p1_interact"},{type:"wait", ms:300}]});
  await call("take_screenshot", {responseMode:"path_only"});
  await call("get_debug_output", {});
} finally { await call("stop_project", {}); await c.close(); console.log(fail?"RESULT FAIL":"RESULT OK"); }
