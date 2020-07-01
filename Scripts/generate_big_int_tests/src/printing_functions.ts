import { allPossiblePairings } from './all_pairings';
import { generateSmiNumbers, generateHeapNumbers } from './number_generators';

const smiNumbers = generateSmiNumbers(10);
const heapNumbers = generateHeapNumbers(10);

const smiSmiPairs = allPossiblePairings(smiNumbers, smiNumbers);
const smiHeapPairs = allPossiblePairings(smiNumbers, heapNumbers);
const heapSmiPairs = allPossiblePairings(heapNumbers, smiNumbers);
const heapHeapPairs = allPossiblePairings(heapNumbers, heapNumbers);

// =======================
// === BinaryOperation ===
// =======================

export type BinaryOperation = (lhs: bigint, rhs: bigint) => bigint;

export function printBinaryOperationTests(name: string, op: BinaryOperation) {
  const nameLower = name.toLowerCase();

  console.log(`  // MARK: - ${name}`);
  console.log();

  // smi, smi
  console.log(`  func test_${nameLower}_smi_smi() {`);
  for (const { lhs, rhs } of smiSmiPairs) {
    const expected = op(lhs, rhs);
    console.log(`    self.${nameLower}Test(lhs: "${lhs}", rhs: "${rhs}", expecting: "${expected}")`);
  }
  console.log('  }');
  console.log();

  // smi, heap
  console.log(`  func test_${nameLower}_smi_heap() {`);
  for (const { lhs, rhs } of smiHeapPairs) {
    const expected = op(lhs, rhs);
    console.log(`    self.${nameLower}Test(lhs: "${lhs}", rhs: "${rhs}", expecting: "${expected}")`);
  }
  console.log('  }');
  console.log();

  // heap, smi
  console.log(`  func test_${nameLower}_heap_smi() {`);
  for (const { lhs, rhs } of heapSmiPairs) {
    const expected = op(lhs, rhs);
    console.log(`    self.${nameLower}Test(lhs: "${lhs}", rhs: "${rhs}", expecting: "${expected}")`);
  }
  console.log('  }');
  console.log();

  // heap, heap
  console.log(`  func test_${nameLower}_heap_heap() {`);
  for (const { lhs, rhs } of heapHeapPairs) {
    const expected = op(lhs, rhs);
    console.log(`    self.${nameLower}Test(lhs: "${lhs}", rhs: "${rhs}", expecting: "${expected}")`);
  }
  console.log('  }');
  console.log();
}
