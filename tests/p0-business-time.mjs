import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import ts from "typescript";
const source = fs.readFileSync(new URL("../lib/business-time.ts", import.meta.url), "utf8");
const compiled = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
const context = { exports: {}, Intl, Date, Error };
vm.runInNewContext(compiled, context);
const { fromBusinessLocalInput: parse, toBusinessLocalInput: display } = context.exports;
let passed = 0;
function check(name, run) { run(); passed++; console.log("PASS " + name); }
check("MYT entry preserves intended instant", () => assert.equal(parse("2026-10-12T10:30"), "2026-10-12T02:30:00.000Z"));
check("MYT midnight crosses UTC day", () => assert.equal(parse("2026-10-12T00:05"), "2026-10-11T16:05:00.000Z"));
check("UTC instant renders next business day", () => assert.equal(display("2026-10-11T23:30:00Z"), "2026-10-12T07:30"));
check("Leap day accepted", () => assert.equal(parse("2028-02-29T12:00"), "2028-02-29T04:00:00.000Z"));
check("Edit roundtrip retains minute", () => assert.equal(parse(display("2026-10-12T02:30:00Z")), "2026-10-12T02:30:00.000Z"));
check("Blank optional input", () => assert.equal(parse(""), null));
check("Null optional input", () => assert.equal(parse(null), null));
check("Missing display input", () => assert.equal(display(null), ""));
for (const input of ["2026-02-29T10:30", "2026-04-31T10:30", "2026-10-12T24:30", "2026-10-12T10:60", "invalid", "2026-10-12T10:30Z"]) {
  check("Reject malformed/calendar input " + input, () => assert.throws(() => parse(input)));
}
check("Invalid stored date rejected", () => assert.throws(() => display("invalid")));
const leadSource = fs.readFileSync(new URL("../lib/marketing-leads.ts", import.meta.url), "utf8");
const leadCompiled = ts.transpileModule(leadSource, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
const leadContext = { exports: {}, Intl, Date };
vm.runInNewContext(leadCompiled, leadContext);
check("Lead display uses MYT independently of runtime timezone", () => assert.match(leadContext.exports.formatLeadDate("2026-10-11T23:30:00Z"), /12 Oct 2026, 7:30 am/));
check("Missing lead date retains placeholder", () => assert.equal(leadContext.exports.formatLeadDate(null), "—"));
console.log(passed + "/17 PASS");
