// Completion is checked with a deliberate diagnostic, independently of how
// many real source files still have type errors.
import path from 'node:path';

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
