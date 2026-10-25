// The game's copy of the stylebook theme is the only source of motion numbers.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const input = path.join(project, '..', 'Assets', 'UI', 'bouncy-motion.theme.json');
const output = path.join(project, 'src', 'shared', 'UiMotionTheme.luau');
const motion = JSON.parse(fs.readFileSync(input, 'utf8')).motion;
for (const key of ['hover', 'press', 'release', 'open', 'close', 'hud', 'blur', 'disabled']) {
  if (!motion?.[key]) throw new Error('Missing motion.' + key);
}
const curves = new Set(['linear', 'quadIn', 'quadOut', 'quartIn', 'quartOut']);
function luau(value, depth = 0) {
  if (typeof value === 'number') {
    if (!Number.isFinite(value) || value < 0) throw new Error('Invalid motion number');
    return String(value);
  }
  if (typeof value === 'boolean') return String(value);
  if (typeof value === 'string') return JSON.stringify(value) + ' :: ' + JSON.stringify(value);
  const tab = '\t'.repeat(depth + 1);
  return '{\n' + Object.entries(value).map(([key, item]) => {
    if (!/^[A-Za-z][A-Za-z0-9]*$/.test(key)) throw new Error('Invalid token name: ' + key);
    if (/Easing$|^easing$/.test(key) && !curves.has(item)) throw new Error('Unsupported easing: ' + item);
    return tab + key + ' = ' + luau(item, depth + 1) + ',';
  }).join('\n') + '\n' + '\t'.repeat(depth) + '}';
}
if (motion.open.from !== motion.close.to || motion.open.overshoot !== motion.close.anticipationScale) {
  throw new Error('Open and close motion must share their endpoints');
}
if (motion.hover.scale * motion.release.overshootMultiplier > motion.release.maximumScale) {
  throw new Error('Release overshoot exceeds the reserved layout maximum');
}
const source = '--!strict\n-- Generated from Assets/UI/bouncy-motion.theme.json by tools/sync-motion-theme.mjs.\nreturn ' + luau(motion) + '\n';
const formatted = spawnSync('stylua', ['-'], { input: source, encoding: 'utf8', windowsHide: true });
if (formatted.status !== 0) throw new Error(formatted.error?.message || formatted.stderr || 'StyLua failed');
if (process.argv.includes('--check')) {
  if (!fs.existsSync(output) || fs.readFileSync(output, 'utf8') !== formatted.stdout) {
    throw new Error('Motion theme is out of sync: run node RojoTest/tools/sync-motion-theme.mjs');
  }
  console.log('bouncy-motion v3 theme matches runtime tokens.');
} else {
  fs.writeFileSync(output, formatted.stdout);
  console.log('Generated ' + path.relative(project, output));
}
