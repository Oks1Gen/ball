// Completion is checked with a deliberate diagnostic, independently of how
// many real source files still have type errors.
import path from 'node:path';

export function compareFindingCounts(baseline, current) {
  const count = (items) => {
    const counts = new Map();
    for (const item of items) counts.set(item, (counts.get(item) ?? 0) + 1);
    return counts;
  };
  const old = count(baseline), now = count(current);
  const added = [], removed = [];
  for (const key of new Set([...old.keys(), ...now.keys()])) {
    const delta = (now.get(key) ?? 0) - (old.get(key) ?? 0);
    if (delta > 0) added.push({ key, count: delta });
    if (delta < 0) removed.push({ key, count: -delta });
  }
  return { added, removed };
}

export function isProbeDiagnostic(file, probe, project) {
  const resolved = path.resolve(project, file);
  return process.platform === 'win32'
    ? resolved.toLowerCase() === probe.toLowerCase()
    : resolved === probe;
}

export function assertAnalyzerComplete(status, probeFound, unparsedDiagnostics = []) {
  if (status !== 0 && status !== 1) {
    throw new Error('Type analyzer failed with exit code ' + status);
  }
  if (!probeFound) throw new Error('Type analyzer did not report its completion probe');
  if (unparsedDiagnostics.length) {
    throw new Error('Unrecognized analyzer diagnostics: ' + unparsedDiagnostics.join('\n'));
  }
}
