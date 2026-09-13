; /Users/ghostportal/Documents/Codex/2026-09-13/referenced-chatgpt-conversation-this-is-an/work/dcdart/core/examples/m2-loop/loop.dart — emitted by core/backend, not hand-written

target triple = "wasm32-unknown-unknown"

declare void @llvm.trap()
declare {i64, i1} @llvm.uadd.with.overflow.i64(i64, i64)

define i64 @sumTo(i64 %v0) #0 {
entry:
  %v1 = add i64 0, 0
  %v2 = add i64 0, 0
  br label %blk1
blk1:
  %v3 = phi i64 [ %v2, %entry ], [ %v8, %ok7 ]
  %v4 = phi i64 [ %v1, %entry ], [ %v10, %ok7 ]
  %v5 = icmp ult i64 %v4, %v0
  br i1 %v5, label %blk2, label %blk3
blk2:
  %t0 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v3, i64 %v4)
  %v8 = extractvalue {i64, i1} %t0, 0
  %ovf1 = extractvalue {i64, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  %v9 = add i64 1, 0
  %t4 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v4, i64 %v9)
  %v10 = extractvalue {i64, i1} %t4, 0
  %ovf5 = extractvalue {i64, i1} %t4, 1
  br i1 %ovf5, label %trap6, label %ok7
trap6:
  call void @llvm.trap()
  unreachable
ok7:
  br label %blk1
blk3:
  %v6 = phi i64 [ %v3, %blk1 ]
  %v7 = phi i64 [ %v4, %blk1 ]
  ret i64 %v6
}

define i64 @firstAtLeast(i64 %v0, i64 %v1) #0 {
entry:
  %v2 = add i64 0, 0
  %v3 = add i64 0, 0
  br label %blk1
blk1:
  %v4 = phi i64 [ %v3, %entry ], [ %v9, %ok7 ]
  %v5 = phi i64 [ %v2, %entry ], [ %v12, %ok7 ]
  %v6 = icmp ult i64 %v5, %v0
  br i1 %v6, label %blk2, label %blk3
blk2:
  %t0 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v4, i64 %v5)
  %v9 = extractvalue {i64, i1} %t0, 0
  %ovf1 = extractvalue {i64, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  %v10 = icmp ult i64 %v1, %v9
  br i1 %v10, label %blk4, label %blk5
blk4:
  ret i64 %v5
blk5:
  %v11 = add i64 1, 0
  %t4 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v5, i64 %v11)
  %v12 = extractvalue {i64, i1} %t4, 0
  %ovf5 = extractvalue {i64, i1} %t4, 1
  br i1 %ovf5, label %trap6, label %ok7
trap6:
  call void @llvm.trap()
  unreachable
ok7:
  br label %blk1
blk3:
  %v7 = phi i64 [ %v4, %blk1 ]
  %v8 = phi i64 [ %v5, %blk1 ]
  ret i64 %v8
}

attributes #0 = { nounwind "no-builtins" }
