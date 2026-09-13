import '../../../runtime/dc-core-bare/prelude.dart';
class Inner extends HeapObject { final u64 value; const Inner(this.value); }
class Outer extends HeapObject { final Inner inner; const Outer(this.inner); }
@bare Inner makeInner(u64 n) => Inner(n);
@bare Outer direct(u64 n) => Outer(makeInner(n));
@bare Outer nested(u64 n) => Outer(Inner(n));
@bare void drop(@owned Outer o) {}
@bare u64 read(Inner x) => x.value;
@bare u64 borrowed(u64 n) => read(makeInner(n));
@bare u64 field(u64 n) => makeInner(n).value;

class Pair extends HeapObject {
  final Inner a;
  final Inner b;
  Pair(Inner value): a = value, b = value;
}
@bare u64 shared(u64 n) { final p = Pair(makeInner(n)); return p.a.value + p.b.value; }
@bare Inner escaped(u64 n) => Outer(Inner(n)).inner;
@bare void dropInner(@owned Inner x) {}
@bare u64 localBorrow(u64 n) { u64 take(Inner x) => x.value; return take(makeInner(n)); }
@bare u64 indirectBorrow(u64 n) { final fn = read; return fn(makeInner(n)); }
@bare u64 weakTemporary(u64 n) {
  final w = Weak<Inner>.fromStrong(makeInner(n));
  final x = w.value;
  if (x == null) return u64(1);
  return u64(0);
}

class Reader extends HeapObject {
  final u64 value;
  Reader(this.value);
  Inner create() => Inner(value);
  u64 consume(@owned Inner x) => x.value;
  u64 borrow(Inner x) => x.value;
}
@bare u64 methodFresh(u64 n) => Reader(n).create().value;
@bare u64 methodBorrow(u64 n) { final r = Reader(n); return r.borrow(Inner(n)); }
@bare u64 methodOwned(u64 n) { final r = Reader(n); final x = Inner(n); return r.consume(x) + x.value; }
@bare u64 methodOwnedFresh(u64 n) => Reader(n).consume(Inner(n));

@bare void discardIndirect(u64 n) { final fn = makeInner; fn(n); }
@bare u64 freshNull(u64 n) { if (makeInner(n) != null) return u64(1); return u64(0); }
