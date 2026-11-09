// Read-only CEO balance model. Run from any directory with Node.
// Snapshot formulas: Economy, GameConfig, SkippingGame, Training, TrainingBoost.
// This is a sensitivity model, not a simulated player session or telemetry.
import fs from 'node:fs';

const economy = fs.readFileSync(new URL('../RojoTest/src/shared/Core/Economy.luau', import.meta.url), 'utf8');
const constant = name => {
  const match = economy.match(new RegExp(`Economy\\.${name} = ([0-9.e+]+)`));
  if (!match) throw new Error(`Missing constant: ${name}`);
  return Number(match[1]);
};
const base = constant('RebirthBaseSkill');
const growth = constant('RebirthSkillGrowth');
const exponent = constant('ShotDistanceExponent');
const floor = constant('ShotDistanceFloor');
// World1 limit read through Studio MCP on 2026-11-08; depends on authored scene.
const limit = 17897;
const oldRate = 7 / 0.8;
const thresholds = [0, 2, 4, 6, 9, 12, 16];
const oldLanes = [1, 2, 4, 8, 16, 32, 64];
const newLanes = [1, 1.35, 1.8, 2.4, 3.2, 4.2, 5.5];
const laneIndex = r => thresholds.filter(g => g <= r).length - 1;
const distance = (skill, power = 1) => Math.floor(floor + (limit - floor) * Math.min(1, skill * power / 1e6) ** exponent);
const petTeam = boosts => 1 + boosts.reduce((sum, boost) => sum + boost - 1, 0);
const minutes = (rate, multiplier) => base / (rate * multiplier) / 60;
// One boosted 1.2-second cycle per 7-second offer; four of five offers are free.
// Ignores contact rounding, collection misses, interruption and travel.
const activeMean = boostMean => 1 + (boostMean - 1) * 1.2 / 7 * 4 / 5;
const oldDrawMean = 0.45 * 1.2 + 0.3 * 1.5 + 0.2 * 2.5 + 0.05 * 8;
const newDrawMean = 0.55 * 1.15 + 0.3 * 1.3 + 0.14 * 1.6 + 0.01 * 2.2;
const p = 0.0005;
const quantile = q => Math.ceil(Math.log(1 - q) / Math.log(1 - p));
const result = {
  date: '2026-11-08',
  scope: 'Read-only model; proposed values are unimplemented hypotheses',
  sources: { base, growth, exponent, floor, limit, oldBaseSkillPerSecond: oldRate },
  current: {
    legendaryChanceWithin20: 1 - 0.95 ** 20,
    legendaryChanceWithin60: 1 - 0.95 ** 60,
    threeCommonTeam: petTeam([1.2, 1.2, 1.2]),
    threeRainbowCommonTeam: petTeam([18, 18, 18]),
    threeRainbowLegendaryTeam: petTeam([120, 120, 120]),
    teamAtThreeDrawMean: 1 + 3 * (oldDrawMean - 1),
    approximateActiveFactor: activeMean(10),
    giftsWinsThrough15Minutes: 100 + 500 + 1000 + 2500 + 10000,
    giftsWinsThrough30Minutes: 100 + 500 + 1000 + 2500 + 10000 + 50000,
    firstRebirthMinutesNoBonuses: minutes(oldRate, 1),
    firstRebirthMinutesOneLegendaryNoOtherBonuses: minutes(oldRate, 8),
    firstRebirthMinutesRainbowLegendaryTeamNoOtherBonuses: minutes(oldRate, 358),
    fullCourseSkillApproxPerfect: Math.ceil(1e6 * ((limit / 6 - floor) / (limit - floor)) ** (1 / exponent)),
    shots: [30, 1000, 10000, 20000, 50000].map(skill => ({ skill, auto: distance(skill), perfect: Math.min(limit, distance(skill) * 6) })),
  },
  proposed: {
    baseSkillPerSecond: 35,
    firstEggWeightsPercent: [55, 30, 14, 1],
    firstEggBoosts: [1.15, 1.3, 1.6, 2.2],
    teamAtThreeDrawMean: 1 + 3 * (newDrawMean - 1),
    approximateActiveFactor: activeMean(2),
    // Fixed loadouts throughout. Excludes earning/equipping pets and travel.
    firstRebirthMinutesThreeCommons: minutes(35, petTeam([1.15, 1.15, 1.15]) * activeMean(2)),
    firstRebirthMinutesTeamAtThreeDrawMean: minutes(35, (1 + 3 * (newDrawMean - 1)) * activeMean(2)),
    firstRebirthMinutesNoBonuses: minutes(35, 1),
    perfectTimingPower: 1.35,
    fullCourseSkillPerfect: Math.ceil(1e6 / 1.35),
    shots: [30, 1000, 10000, 20000, 50000].map(skill => ({ skill, auto: distance(skill), perfect: distance(skill, 1.35) })),
  },
  rebirthSensitivity: [0, 2, 4, 6, 9, 12, 16, 20, 30].map(r => ({
    completedRebirths: r,
    currentRequirement: Math.floor(base * growth ** r),
    // Time relative to the same model at r=0, holding pets/ball/world/activity fixed.
    currentRelativeTrainingTime: growth ** r / ((1 + r) * oldLanes[laneIndex(r)]),
    proposedRequirement: Math.floor(base * 1.4 ** r),
    proposedRelativeTrainingTime: (1.4 / 1.2) ** r / newLanes[laneIndex(r)],
    proposedSupportedRange: r <= 16,
  })),
  secret: {
    chance: p,
    meanHatches: 1 / p,
    medianHatches: quantile(0.5),
    p90Hatches: quantile(0.9),
    p95Hatches: quantile(0.95),
    chanceWithin100: 1 - (1 - p) ** 100,
    chanceWithin1000: 1 - (1 - p) ** 1000,
    chanceWithin2000: 1 - (1 - p) ** 2000,
    assumptions: 'Independent identical rolls; no luck, guarantee, pity or restriction fallback',
  },
};
console.log(JSON.stringify(result, null, 2));
