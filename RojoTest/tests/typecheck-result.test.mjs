import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { assertAnalyzerComplete, isProbeDiagnostic } from '../tools/typecheck-result.mjs';

test('a clean project and a project with few errors accept a completed analyzer', () => {
  assert.doesNotThrow(() => assertAnalyzerComplete(1, true));
});
test('crashes and missing or unreadable completion diagnostics fail closed', () => {
  assert.throws(() => assertAnalyzerComplete(2, true));
  assert.throws(() => assertAnalyzerComplete(0, false));
  assert.throws(() => assertAnalyzerComplete(1, false));
  assert.throws(() => assertAnalyzerComplete(1, true, ['unreadable diagnostic']));
});

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = fs.readFileSync(path.join(project, '..', 'rokit.toml'), 'utf8');
const pin = manifest.match(/^luau-lsp = "([^/]+)\/([^@]+)@([^"\r\n]+)"/m);
assert.ok(pin);
const analyzer = path.join(os.homedir(), '.rokit', 'tool-storage', pin[1].toLowerCase(), pin[2], pin[3],
  'luau-lsp' + (process.platform === 'win32' ? '.exe' : ''));

for (const broken of [false, true]) {
  test('real analyzer completes with ' + (broken ? 'one real type error' : 'clean game code'), () => {
    const dir = fs.mkdtempSync(path.join(project, '.tools', 'analyzer-fixture-'));
    try {
      const source = path.join(dir, 'source.luau');
      const probe = path.join(dir, 'probe.luau');
      fs.writeFileSync(source, broken ? 'local _value: number = "wrong"\n' : 'local _value: number = 42\n');
      fs.writeFileSync(probe, 'local _completion: number = "probe"\n');
      const result = spawnSync(analyzer, ['analyze', source, probe], {
        cwd: project, encoding: 'utf8', windowsHide: true, timeout: 30000,
      });
      assert.ifError(result.error);
      const output = result.stdout + result.stderr;
      const diagnostics = [...output.matchAll(/^(.+?)\s*(?:\[[^\]]*\])?\(\d+,\d+\): (\w+): .*$/gm)];
      const probeFound = diagnostics.some((row) => isProbeDiagnostic(row[1], probe, project) && row[2] === 'TypeError');
      assert.doesNotThrow(() => assertAnalyzerComplete(result.status, probeFound));
      assert.equal(diagnostics.filter((row) => !isProbeDiagnostic(row[1], probe, project)).length, broken ? 1 : 0);
    } finally {
      // Only this test's freshly created directory inside .tools is removed.
      const relative = path.relative(path.join(project, '.tools'), path.resolve(dir));
      assert.ok(relative && !relative.startsWith('..') && !path.isAbsolute(relative));
      fs.rmSync(dir, { recursive: true });
    }
  });
}
