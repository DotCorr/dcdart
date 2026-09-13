import '../../../runtime/dc-core-bare/prelude.dart';
@extern
external i32 abs(i32 value);
@bare
i32 apply(i32 Function(i32) fn, i32 value) => fn(value);
@bare
i32 indirect(i32 value) => apply(abs, value);
@bare
i32 Function(i32) address() => abs;
