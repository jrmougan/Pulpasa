// Sesión MCP real por stdio contra godot-mcp-runtime@4.0.1, como la arranca .mcp.json.
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { spawn } from "node:child_process";
import { copyFileSync } from "node:fs";
const proj = process.argv[2], scene = process.argv[3], out = process.argv[4];
const t = new StdioClientTransport({ command: "npx", args: ["-y","godot-mcp-runtime@4.0.1"],
  env: {...process.env, GODOT_MCP_DISABLE_ELICITATION:"true"}, stderr: "inherit" });
const c = new Client({name:"pulpasa-probe",version:"0"});
await c.connect(t);
const show = (n, r) => { const txt = r.content.filter(x=>x.type==="text").map(x=>x.text).join("\n");
  console.log(`--- ${n} isError=${!!r.isError} images=${r.content.filter(x=>x.type==="image").length}\n${txt.slice(0,1800)}`); return txt; };
let godot;
let fail = 0;
try {
  const callP = c.callTool({name:"run_project", arguments:{projectPath: proj, attach: true}}, undefined, {timeout: 120000});
  await new Promise(r=>setTimeout(r,1500));
  godot = spawn("xvfb-run", ["-a","-s","-screen 0 1920x1080x24", "godot","--audio-driver","Dummy","--path",proj, scene], {stdio:["ignore","pipe","pipe"], detached:true});
  let glog=""; godot.stdout.on("data",d=>glog+=d); godot.stderr.on("data",d=>glog+=d);
  console.log("godot (xvfb-run) pid", godot.pid);
  const r1 = await callP; show("run_project attach", r1); fail |= !!r1.isError;
  await new Promise(r=>setTimeout(r,4000));
  const r2 = await c.callTool({name:"take_screenshot", arguments:{responseMode:"path_only"}}); const s1 = show("take_screenshot #1", r2); fail |= !!r2.isError;
  const r3 = await c.callTool({name:"simulate_input", arguments:{actions:[
    {type:"action", action:"p1_move_right", hold_ms:600},
    {type:"action", action:"p1_move_up", hold_ms:400},
    {type:"wait", ms:300},
    {type:"key", key:"Escape"},
    {type:"wait", ms:300}]}}); show("simulate_input", r3); fail |= !!r3.isError;
  const r4 = await c.callTool({name:"take_screenshot", arguments:{responseMode:"path_only"}}); const s2 = show("take_screenshot #2", r4); fail |= !!r4.isError;
  for (const [txt, name] of [[s1,"1"],[s2,"2"]]) { const m = txt.match(/"(\/[^"]+\.png)"/); if (m) { copyFileSync(m[1], `${out}/mcp-screenshot-${name}.png`); console.log("copied", m[1]); } }
  const r5 = await c.callTool({name:"stop_project", arguments:{}}); show("stop_project", r5); fail |= !!r5.isError;
  console.log("--- godot log (errores):\n" + glog.split("\n").filter(l=>/ERROR/.test(l)).slice(0,20).join("\n"));
} catch (e) { console.log("EXC", e); fail = 1; }
finally {
  if (godot && godot.exitCode === null) { try { process.kill(-godot.pid, "SIGTERM"); } catch {} }
  await c.close();
  console.log(fail ? "RESULT FAIL" : "RESULT OK");
}
