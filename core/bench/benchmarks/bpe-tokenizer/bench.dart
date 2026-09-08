// core/bench/benchmarks/bpe-tokenizer/bench.dart
//
// NEON N2 candidate (3rd of the four workloads neon/ROADMAP.md N2 names):
// greedy byte-pair-encoding tokenization -- the ARC-HEAVY half of the ML
// suite, together with `data-pipeline/`. The float pair (matmul-f32,
// attention-f32) prices codegen with zero ARC in the hot path; this pair
// prices the OTHER thing an ML stack does all day: allocate, link, unlink
// and drop small objects. BENCH_SUITE=diagnostic -- NOT one of M3's five,
// enters no gate mean.
//
// THE WORKLOAD. Train a 256-rule merge table over a 16,384-symbol synthetic
// corpus (greedy: count adjacent pairs, merge the most frequent, repeat),
// then encode a rolling 2048-symbol window `rounds` times by applying the
// rules in rank order. Checksum folds every argmax pick, the trained length,
// and every output token id modularly -- a tokenizer that merges the wrong
// pair anywhere produces a different checksum and the harness refuses the
// ratio.
//
// WHERE THE ARC IS, deliberately. The C side does what every real tokenizer
// in C does: flat arrays and indices (see kernel.c). DCDart CANNOT do that
// for object-shaped data -- there is no array of ARC references (GAP-0061)
// -- and this benchmark, unlike `hashmap`, does NOT make C mirror the
// linked structure. That asymmetry is the point, not a fairness bug: N2's
// question is "what does ML string processing cost UNDER ARC, written the
// way the language makes you write it", so:
//
//   * the merge table is a linked list of `Merge` nodes (C: a struct array)
//   * training's distinct-pair worklist is a linked list of `PairNode`s,
//     re-allocated and dropped EVERY round -- ~256 rounds x thousands of
//     nodes of alloc/release churn per kernel call (C: a u32 index array)
//   * the encode window is a linked list of `Token` nodes, one per symbol;
//     a merge is an in-place id rewrite plus an UNLINK, which is a release
//     (C: in-place array compaction); the whole list dies by destructor
//     cascade (ADR-0022) at end of window
//
// The flat NUMERIC buffers (corpus, pair-count table) are raw `Heap.allocate`
// bytes on both sides -- same idiom as `string-pass` -- so the ratio is not
// also charged for GAP-0061 on data that is not object-shaped. Their
// Pointer<T> accesses are ordinary loads/stores since ADR-0069, but every
// indexed access is still spelled `base + i * u64(4)` -- user-level TRAPPING
// u64 address arithmetic plus an inttoptr per element (GAP-0070) -- and that
// cost IS in the ratio; the manifest says so.
//
// TRAVERSAL DISCIPLINE, same reasoning as `hashmap`'s trie descent: walks
// that only READ the lists (argmax, rule application, checksum fold) recurse
// on borrowed `HeapObject` parameters (ADR-0019, zero ARC traffic) rather
// than reassigning a heap-typed local (ADR-0048, a retain/release per step).
// The ARC this benchmark prices is the churn the workload actually does --
// allocation, field relink, unlink, cascade -- not a traversal workaround
// tax. Recursion depth is bounded: <= 16,383 (distinct pairs, worst case)
// for argmax, <= 2048 (window) for a rule pass, and the deepest destructor
// cascade is one training round's distinct list (<= 16,383 frames of the
// synthesized dtor -- fine on a hosted 8 MiB stack; same order as
// tree-traversal's 16,383-node cascade).
//
// HEAP SIZING against ADR-0058's default 2 MiB-per-class regions (the
// configuration DCDart ships; nothing here raises it) -- the arithmetic:
//
//   32-byte class:  Token (8 id + 8 next = 16 + 16 hdr = 32), PairNode
//                   (16 + 16 = 32), MergeTable (16 + 16 = 32). Capacity
//                   2 MiB / 32 = 65,536. High water = one training round's
//                   distinct list, bounded by len-1 = 16,383 (a pair must
//                   OCCUR to be counted), later the 2048-token window: max
//                   ~16,384 << 65,536.
//   64-byte class:  Merge (24 + 8 next = 32 + 16 = 48 -> 64). 256 live.
//   raw bytes:      two 16,384 x u32 corpus buffers = 64 KiB each (64 KiB
//                   class, 32 blocks/region, 2 live) + one 320*320 x u32
//                   pair-count table = 400 KiB (512 KiB class, 4 blocks,
//                   1 live).
//
// VOCAB IS CAPPED AT 320 = 64 base symbols + 256 merges, so a pair id is
// < 102,400 and the count table is a flat 400 KiB -- small enough to fit,
// big enough that DCDart's volatile accesses to it are a real term.
//
// TRAP-SAFETY (spec section 4.1, no wrapping operators exist): the LCG state
// is masked to 31 bits so its multiply stays under 2^62; pair ids are
// < 102,400; checksum folds are acc*31 + v with acc < 1e9. Nothing here can
// overflow, so both sides compute in u64 and kernel_trapck.c's checks never
// fire.
import '../../../runtime/dc-core-bare/prelude.dart';

/// One symbol of the encode window. A merge rewrites `id` in place and
/// unlinks the right-hand node -- the unlink is the ARC event.
class Token extends HeapObject {
  u64 id;
  Token? next;
  Token(this.id, this.next);
}

/// One distinct adjacent pair seen in a training round. The list is rebuilt
/// (and dropped, by cascade) every round -- that churn is the training
/// half's ARC load.
class PairNode extends HeapObject {
  u64 pair;
  PairNode? next;
  PairNode(this.pair, this.next);
}

/// One merge rule, in rank order. C keeps these in a struct array.
class Merge extends HeapObject {
  u64 left;
  u64 right;
  u64 id;
  Merge? next;
  Merge(this.left, this.right, this.id, this.next);
}

/// Head+tail holder so training can append in rank order through fields
/// instead of reassigning heap-typed locals. `tail` is a second strong
/// reference to the last node -- no cycle (nothing points back).
class MergeTable extends HeapObject {
  Merge? head;
  Merge? tail;
  MergeTable(this.head, this.tail);
}

/// Fills `addr` with `n` u32 symbols in 0..63 with realistic pair-frequency
/// skew: 5/16 of positions repeat the previous symbol (frequent bigrams --
/// what makes greedy BPE merge productively) and the rest draw from a
/// quadratically-skewed map of the LCG output (frequent unigrams). Serial
/// dependency via `prev`, so neither side can vectorise it away.
@bare void genCorpus(u64 addr, u64 n) {
  var x = u64(20260827);
  var prev = u64(0);
  var i = u64(0);
  while (i < n) {
    x = (x * u64(1103515245) + u64(12345)) & u64(0x7FFFFFFF);
    final r = (x >> u64(16)) & u64(15);
    final y = (x >> u64(8)) & u64(63);
    var sym = (y * y) ~/ u64(64);
    if (r < u64(5)) {
      if (u64(0) < i) {
        sym = prev;
      }
    }
    Pointer<u32>.fromAddress(addr + i * u64(4)).value = sym.toU32();
    prev = sym;
    i = i + u64(1);
  }
}

@bare void copyU32(u64 dst, u64 src, u64 n) {
  var i = u64(0);
  while (i < n) {
    Pointer<u32>.fromAddress(dst + i * u64(4)).value =
        Pointer<u32>.fromAddress(src + i * u64(4)).value;
    i = i + u64(1);
  }
}

/// Explicit zero of the count table. The zero-on-entry invariant (every
/// round zeroes exactly the slots it counted) would make this redundant
/// after round one, but an explicit pass on BOTH sides is deterministic by
/// construction rather than by an argument about allocator block reuse.
@bare void zeroTable(u64 cntAddr, u64 slots) {
  var i = u64(0);
  while (i < slots) {
    Pointer<u32>.fromAddress(cntAddr + i * u64(4)).value = u32(0);
    i = i + u64(1);
  }
}

/// Prepends one distinct pair to the sentinel's list. A separate function
/// so the (heap-typed) temporaries live in a frame of their own rather
/// than in a fall-through if-branch, which dcc-lower rejects.
@bare void prependDistinct(PairNode sent, u64 p) {
  final tl = sent.next;
  final node = PairNode(p, tl);
  sent.next = node;
}

/// Counts every adjacent pair of the current training sequence and returns
/// a SENTINEL node whose `next` is the distinct-pair worklist (order
/// irrelevant -- argmax tie-breaks on the pair id, so DCDart may prepend
/// where C appends). The sentinel exists because dcc-lower rejects
/// reassigning a heap-typed LOCAL inside a fall-through branch (ADR-0027's
/// rule) while a FIELD prepend in a branch is the fully supported `hashmap`
/// idiom; its `pair` field is never read.
@bare PairNode countPairs(u64 tAddr, u64 len, u64 cntAddr) {
  final sent = PairNode(u64(0), null);
  var a = Pointer<u32>.fromAddress(tAddr).value.toU64();
  var i = u64(1);
  while (i < len) {
    final b = Pointer<u32>.fromAddress(tAddr + i * u64(4)).value.toU64();
    final p = a * u64(320) + b;
    final slot = Pointer<u32>.fromAddress(cntAddr + p * u64(4));
    final c = slot.value.toU64();
    if (c == u64(0)) {
      prependDistinct(sent, p);
    }
    slot.value = (c + u64(1)).toU32();
    a = b;
    i = i + u64(1);
  }
  return sent;
}

/// Most frequent pair; ties break to the SMALLEST pair id so the answer
/// does not depend on worklist order (DCDart's list is reversed relative to
/// C's first-seen array). Borrowed-parameter recursion: zero ARC traffic.
@bare u64 argmaxPair(PairNode d, u64 cntAddr, u64 bestP, u64 bestC) {
  final p = d.pair;
  final c = Pointer<u32>.fromAddress(cntAddr + p * u64(4)).value.toU64();
  var nbP = bestP;
  var nbC = bestC;
  if (bestC < c) {
    nbP = p;
    nbC = c;
  }
  if (c == bestC) {
    if (p < bestP) {
      nbP = p;
    }
  }
  final nx = d.next;
  if (nx != null) {
    return argmaxPair(nx, cntAddr, nbP, nbC);
  }
  return nbP;
}

/// Re-zeroes exactly the slots this round counted, restoring the all-zero
/// table for the next round. Borrowed recursion; the list itself dies by
/// cascade when the caller's reference goes out of scope.
@bare void zeroCounts(PairNode d, u64 cntAddr) {
  Pointer<u32>.fromAddress(cntAddr + d.pair * u64(4)).value = u32(0);
  final nx = d.next;
  if (nx != null) {
    zeroCounts(nx, cntAddr);
  }
}

/// Left-to-right non-overlapping merge over the flat training sequence,
/// compacted in place. A merged token is NOT re-compared with its follower
/// in the same pass (i advances past the pair) -- the list-based encode
/// pass below implements the identical rule.
@bare u64 mergePass(u64 tAddr, u64 len, u64 left, u64 right, u64 nid) {
  var i = u64(0);
  var j = u64(0);
  while (i < len) {
    final a = Pointer<u32>.fromAddress(tAddr + i * u64(4)).value.toU64();
    var merged = u64(0);
    if (i + u64(1) < len) {
      if (a == left) {
        final b =
            Pointer<u32>.fromAddress(tAddr + (i + u64(1)) * u64(4)).value.toU64();
        if (b == right) {
          Pointer<u32>.fromAddress(tAddr + j * u64(4)).value = nid.toU32();
          i = i + u64(2);
          merged = u64(1);
        }
      }
    }
    if (merged == u64(0)) {
      Pointer<u32>.fromAddress(tAddr + j * u64(4)).value = a.toU32();
      i = i + u64(1);
    }
    j = j + u64(1);
  }
  return j;
}

@bare void mtAppend(MergeTable mt, u64 left, u64 right, u64 nid) {
  final node = Merge(left, right, nid, null);
  final t = mt.tail;
  if (t != null) {
    t.next = node;
  }
  if (t == null) {
    mt.head = node;
  }
  mt.tail = node;
}

/// 256 greedy rounds: count, argmax, record the rule, merge in place, zero
/// the counted slots. Folds every argmax pick and the final sequence length
/// into the checksum so a training divergence anywhere is refused.
@bare u64 train(u64 tAddr, MergeTable mt, u64 cntAddr, u64 acc0) {
  var len = u64(16384);
  var acc = acc0;
  var m = u64(0);
  while (m < u64(256)) {
    final sent = countPairs(tAddr, len, cntAddr);
    final dl = sent.next;
    if (dl != null) {
      final bestP = argmaxPair(dl, cntAddr, u64(102400), u64(0));
      final left = bestP ~/ u64(320);
      final right = bestP % u64(320);
      final nid = u64(64) + m;
      mtAppend(mt, left, right, nid);
      len = mergePass(tAddr, len, left, right, nid);
      acc = (acc * u64(31) + bestP) % u64(1000000007);
      zeroCounts(dl, cntAddr);
    }
    m = m + u64(1);
  }
  return (acc * u64(31) + len) % u64(1000000007);
}

/// One `Token` node per window symbol, built by recursion (depth = window).
@bare Token? buildTokens(u64 srcAddr, u64 i, u64 end) {
  if (end <= i) {
    return null;
  }
  final sym = Pointer<u32>.fromAddress(srcAddr + i * u64(4)).value.toU64();
  // Bound to a local, NOT nested as `Token(sym, buildTokens(...))`: a fresh
  // temporary passed straight to a borrowed constructor parameter is never
  // released (GAP-0065) -- the nested form leaked the entire list, caught by
  // the harness's dc_heap_live check on this benchmark's first run.
  final rest = buildTokens(srcAddr, i + u64(1), end);
  return Token(sym, rest);
}

/// One rule pass over the token list -- the same left-to-right
/// non-overlapping rule as [mergePass]: on a match, rewrite the left node's
/// id, UNLINK the right node (`n.next = nx.next` releases it -- the GAP-0054
/// family shape, `unlinkFrom`'s sibling, handled since ADR-0063), and
/// continue AFTER the pair. The head node is never unlinked, so the caller's
/// reference stays valid across every pass.
@bare void applyRule(Token n, u64 left, u64 right, u64 nid) {
  final nx = n.next;
  if (nx != null) {
    if (n.id == left) {
      if (nx.id == right) {
        n.id = nid;
        n.next = nx.next;
        final nn = n.next;
        if (nn != null) {
          applyRule(nn, left, right, nid);
        }
        return;
      }
    }
    applyRule(nx, left, right, nid);
  }
}

/// Applies the merge table in rank order (list walk, borrowed recursion).
@bare void applyMerges(Merge m, Token head) {
  applyRule(head, m.left, m.right, m.id);
  final nx = m.next;
  if (nx != null) {
    applyMerges(nx, head);
  }
}

/// Folds the encoded window's token ids, left to right, accumulator in a
/// parameter so the recursion is tail-shaped.
@bare u64 foldTokens(Token n, u64 acc) {
  final a = (acc * u64(31) + n.id) % u64(1000000007);
  final nx = n.next;
  if (nx != null) {
    return foldTokens(nx, a);
  }
  return a;
}

/// Encodes `rounds` rolling windows. Window r starts at (r * 997) % 14336,
/// so consecutive windows overlap but never repeat until r wraps at 14336
/// (997 and 14336 are coprime) -- far beyond any BENCH_ARG this harness
/// will run. A separate function so no heap-typed local is ever declared
/// inside a fall-through branch (dcc-lower rejects that shape).
@bare u64 encodeAll(u64 srcAddr, Merge mh, u64 rounds, u64 acc0) {
  var acc = acc0;
  var r = u64(0);
  while (r < rounds) {
    final start = (r * u64(997)) % (u64(16384) - u64(2048));
    final head = buildTokens(srcAddr, start, start + u64(2048));
    if (head != null) {
      applyMerges(mh, head);
      acc = foldTokens(head, acc);
    }
    // `head`'s list dies here by destructor cascade -- the priced drop.
    r = r + u64(1);
  }
  return acc;
}

/// Train once, then encode `rounds` rolling windows.
@bare u64 benchKernel(u64 rounds) {
  final ntrain = u64(16384);
  final trainBuf = Heap.allocate(ntrain * u64(4));
  final srcBuf = Heap.allocate(ntrain * u64(4));
  final cnt = Heap.allocate(u64(102400) * u64(4));
  genCorpus(trainBuf.address, ntrain);
  copyU32(srcBuf.address, trainBuf.address, ntrain);
  zeroTable(cnt.address, u64(102400));

  final mt = MergeTable(null, null);
  var acc = train(trainBuf.address, mt, cnt.address, u64(0));

  final mh = mt.head;
  if (mh != null) {
    acc = encodeAll(srcBuf.address, mh, rounds, acc);
  }

  Heap.free(trainBuf);
  Heap.free(srcBuf);
  Heap.free(cnt);
  return acc;
}
