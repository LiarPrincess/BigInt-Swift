import { allPossiblePairings, BigIntPair } from './all_pairings';
import { generateSmiNumbers, generateHeapNumbers } from './number_generators';

const smiNumbers = generateSmiNumbers(10);
const heapNumbers = generateHeapNumbers(10);

const smiSmiPairs = allPossiblePairings(smiNumbers, smiNumbers);
const smiHeapPairs = allPossiblePairings(smiNumbers, heapNumbers);
const heapSmiPairs = allPossiblePairings(heapNumbers, smiNumbers);
const heapHeapPairs = allPossiblePairings(heapNumbers, heapNumbers);

// =======================
// === UnaryOperations ===
// =======================

export type UnaryOperation = (value: bigint) => bigint;

export function printUnaryOperationTests(name: string, op: UnaryOperation) {
  const nameLower = name.toLowerCase();
  const testFn = `self.${nameLower}Test`;

  console.log(`  // MARK: - ${name}`);
  console.log();

  printUnaryOperationTest(`${nameLower}_smi`, testFn, smiNumbers, op);
  printUnaryOperationTest(`${nameLower}_heap`, testFn, heapNumbers, op);
}

function printUnaryOperationTest(
  name: string,
  testFn: string,
  values: bigint[],
  op: UnaryOperation
) {
  const isDiv = name.startsWith('div') || name.startsWith('mod');

  console.log(`  func test_${name}() {`);
  for (const value of values) {
    const expected = op(value);
    console.log(`    ${testFn}(value: "${value}", expecting: "${expected}")`);
  }

  console.log('  }');
  console.log();
}

// ========================
// === BinaryOperations ===
// ========================

export type BinaryOperation = (lhs: bigint, rhs: bigint) => bigint;

export function printBinaryOperationTests(name: string, op: BinaryOperation) {
  const nameLower = name.toLowerCase();
  const testFn = `self.${nameLower}Test`;

  console.log(`  // MARK: - ${name}`);
  console.log();

  printBinaryOperationTest(`${nameLower}_smi_smi`, testFn, smiSmiPairs, op);
  printBinaryOperationTest(`${nameLower}_smi_heap`, testFn, smiHeapPairs, op);
  printBinaryOperationTest(`${nameLower}_heap_smi`, testFn, heapSmiPairs, op);
  printBinaryOperationTest(`${nameLower}_heap_heap`, testFn, heapHeapPairs, op);
}

function printBinaryOperationTest(
  name: string,
  testFn: string,
  values: BigIntPair[],
  op: BinaryOperation
) {
  const isDiv = name.startsWith('div') || name.startsWith('mod');

  console.log(`  func test_${name}() {`);
  for (const { lhs, rhs } of values) {
    if (isDiv && rhs == 0n) {
      continue; // Well.. hello there!
    }

    const expected = op(lhs, rhs);
    console.log(`    ${testFn}(lhs: "${lhs}", rhs: "${rhs}", expecting: "${expected}")`);
  }
  console.log('  }');
  console.log();
}
