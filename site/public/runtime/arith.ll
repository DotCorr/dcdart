; /Users/ghostportal/Documents/Codex/2026-09-13/referenced-chatgpt-conversation-this-is-an/work/dcdart/core/examples/m2-arith/arith.dart — emitted by core/backend, not hand-written

target triple = "wasm32-unknown-unknown"

declare void @llvm.trap()
declare {i16, i1} @llvm.umul.with.overflow.i16(i16, i16)
declare {i32, i1} @llvm.umul.with.overflow.i32(i32, i32)
declare {i64, i1} @llvm.uadd.with.overflow.i64(i64, i64)
declare {i64, i1} @llvm.umul.with.overflow.i64(i64, i64)
declare {i8, i1} @llvm.umul.with.overflow.i8(i8, i8)

define i64 @mulU64(i64 %v0, i64 %v1) #0 {
entry:
  %t0 = call {i64, i1} @llvm.umul.with.overflow.i64(i64 %v0, i64 %v1)
  %v2 = extractvalue {i64, i1} %t0, 0
  %ovf1 = extractvalue {i64, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  ret i64 %v2
}

define i32 @mulU32(i32 %v0, i32 %v1) #0 {
entry:
  %t0 = call {i32, i1} @llvm.umul.with.overflow.i32(i32 %v0, i32 %v1)
  %v2 = extractvalue {i32, i1} %t0, 0
  %ovf1 = extractvalue {i32, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  ret i32 %v2
}

define i16 @mulU16(i16 %v0, i16 %v1) #0 {
entry:
  %t0 = call {i16, i1} @llvm.umul.with.overflow.i16(i16 %v0, i16 %v1)
  %v2 = extractvalue {i16, i1} %t0, 0
  %ovf1 = extractvalue {i16, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  ret i16 %v2
}

define i8 @mulU8(i8 %v0, i8 %v1) #0 {
entry:
  %t0 = call {i8, i1} @llvm.umul.with.overflow.i8(i8 %v0, i8 %v1)
  %v2 = extractvalue {i8, i1} %t0, 0
  %ovf1 = extractvalue {i8, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  ret i8 %v2
}

define i64 @divU64(i64 %v0, i64 %v1) #0 {
entry:
  %divzero0 = icmp eq i64 %v1, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v2 = udiv i64 %v0, %v1
  ret i64 %v2
}

define i64 @remU64(i64 %v0, i64 %v1) #0 {
entry:
  %divzero0 = icmp eq i64 %v1, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v2 = urem i64 %v0, %v1
  ret i64 %v2
}

define i32 @divU32(i32 %v0, i32 %v1) #0 {
entry:
  %divzero0 = icmp eq i32 %v1, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v2 = udiv i32 %v0, %v1
  ret i32 %v2
}

define i32 @remU32(i32 %v0, i32 %v1) #0 {
entry:
  %divzero0 = icmp eq i32 %v1, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v2 = urem i32 %v0, %v1
  ret i32 %v2
}

define i8 @divU8(i8 %v0, i8 %v1) #0 {
entry:
  %divzero0 = icmp eq i8 %v1, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v2 = udiv i8 %v0, %v1
  ret i8 %v2
}

define i8 @remU8(i8 %v0, i8 %v1) #0 {
entry:
  %divzero0 = icmp eq i8 %v1, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v2 = urem i8 %v0, %v1
  ret i8 %v2
}

define i64 @gcd(i64 %v0, i64 %v1) #0 {
entry:
  br label %blk1
blk1:
  %v2 = phi i64 [ %v0, %entry ], [ %v3, %divok2 ]
  %v3 = phi i64 [ %v1, %entry ], [ %v8, %divok2 ]
  %v4 = add i64 0, 0
  %v5 = icmp ult i64 %v4, %v3
  br i1 %v5, label %blk2, label %blk3
blk2:
  %divzero0 = icmp eq i64 %v3, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v8 = urem i64 %v2, %v3
  br label %blk1
blk3:
  %v6 = phi i64 [ %v2, %blk1 ]
  %v7 = phi i64 [ %v3, %blk1 ]
  ret i64 %v6
}

define i32 @gcdU32(i32 %v0, i32 %v1) #0 {
entry:
  br label %blk1
blk1:
  %v2 = phi i32 [ %v0, %entry ], [ %v3, %divok2 ]
  %v3 = phi i32 [ %v1, %entry ], [ %v8, %divok2 ]
  %v4 = add i32 0, 0
  %v5 = icmp ult i32 %v4, %v3
  br i1 %v5, label %blk2, label %blk3
blk2:
  %divzero0 = icmp eq i32 %v3, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v8 = urem i32 %v2, %v3
  br label %blk1
blk3:
  %v6 = phi i32 [ %v2, %blk1 ]
  %v7 = phi i32 [ %v3, %blk1 ]
  ret i32 %v6
}

define i64 @digitSum(i64 %v0) #0 {
entry:
  %v1 = add i64 0, 0
  br label %blk1
blk1:
  %v2 = phi i64 [ %v1, %entry ], [ %v10, %divok9 ]
  %v3 = phi i64 [ %v0, %entry ], [ %v12, %divok9 ]
  %v4 = add i64 0, 0
  %v5 = icmp ult i64 %v4, %v3
  br i1 %v5, label %blk2, label %blk3
blk2:
  %v8 = add i64 10, 0
  %divzero0 = icmp eq i64 %v8, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v9 = urem i64 %v3, %v8
  %t3 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v2, i64 %v9)
  %v10 = extractvalue {i64, i1} %t3, 0
  %ovf4 = extractvalue {i64, i1} %t3, 1
  br i1 %ovf4, label %trap5, label %ok6
trap5:
  call void @llvm.trap()
  unreachable
ok6:
  %v11 = add i64 10, 0
  %divzero7 = icmp eq i64 %v11, 0
  br i1 %divzero7, label %divtrap8, label %divok9
divtrap8:
  call void @llvm.trap()
  unreachable
divok9:
  %v12 = udiv i64 %v3, %v11
  br label %blk1
blk3:
  %v6 = phi i64 [ %v2, %blk1 ]
  %v7 = phi i64 [ %v3, %blk1 ]
  ret i64 %v6
}

define i64 @isPrime(i64 %v0) #0 {
entry:
  %v1 = add i64 2, 0
  %v2 = icmp ult i64 %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 0, 0
  ret i64 %v3
blk2:
  %v4 = add i64 2, 0
  br label %blk4
blk4:
  %v5 = phi i64 [ %v4, %blk2 ], [ %v14, %ok10 ]
  %t0 = call {i64, i1} @llvm.umul.with.overflow.i64(i64 %v5, i64 %v5)
  %v6 = extractvalue {i64, i1} %t0, 0
  %ovf1 = extractvalue {i64, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  %v7 = icmp ule i64 %v6, %v0
  br i1 %v7, label %blk5, label %blk6
blk5:
  %divzero4 = icmp eq i64 %v5, 0
  br i1 %divzero4, label %divtrap5, label %divok6
divtrap5:
  call void @llvm.trap()
  unreachable
divok6:
  %v9 = urem i64 %v0, %v5
  %v10 = add i64 0, 0
  %v11 = icmp eq i64 %v9, %v10
  br i1 %v11, label %blk7, label %blk8
blk7:
  %v12 = add i64 0, 0
  ret i64 %v12
blk8:
  %v13 = add i64 1, 0
  %t7 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v5, i64 %v13)
  %v14 = extractvalue {i64, i1} %t7, 0
  %ovf8 = extractvalue {i64, i1} %t7, 1
  br i1 %ovf8, label %trap9, label %ok10
trap9:
  call void @llvm.trap()
  unreachable
ok10:
  br label %blk4
blk6:
  %v8 = phi i64 [ %v5, %ok3 ]
  %v15 = add i64 1, 0
  ret i64 %v15
}

define i64 @powMod(i64 %v0, i64 %v1, i64 %v2) #0 {
entry:
  %divzero0 = icmp eq i64 %v2, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v3 = urem i64 %v0, %v2
  %v4 = add i64 1, 0
  %divzero3 = icmp eq i64 %v2, 0
  br i1 %divzero3, label %divtrap4, label %divok5
divtrap4:
  call void @llvm.trap()
  unreachable
divok5:
  %v5 = urem i64 %v4, %v2
  br label %blk1
blk1:
  %v6 = phi i64 [ %v5, %divok5 ], [ %v18, %divok25 ]
  %v7 = phi i64 [ %v3, %divok5 ], [ %v22, %divok25 ]
  %v8 = phi i64 [ %v1, %divok5 ], [ %v24, %divok25 ]
  %v9 = add i64 0, 0
  %v10 = icmp ult i64 %v9, %v8
  br i1 %v10, label %blk2, label %blk3
blk2:
  %v14 = add i64 2, 0
  %divzero6 = icmp eq i64 %v14, 0
  br i1 %divzero6, label %divtrap7, label %divok8
divtrap7:
  call void @llvm.trap()
  unreachable
divok8:
  %v15 = urem i64 %v8, %v14
  %v16 = add i64 1, 0
  %v17 = icmp eq i64 %v15, %v16
  br i1 %v17, label %blk4, label %blk5
blk4:
  %t9 = call {i64, i1} @llvm.umul.with.overflow.i64(i64 %v6, i64 %v7)
  %v19 = extractvalue {i64, i1} %t9, 0
  %ovf10 = extractvalue {i64, i1} %t9, 1
  br i1 %ovf10, label %trap11, label %ok12
trap11:
  call void @llvm.trap()
  unreachable
ok12:
  %divzero13 = icmp eq i64 %v2, 0
  br i1 %divzero13, label %divtrap14, label %divok15
divtrap14:
  call void @llvm.trap()
  unreachable
divok15:
  %v20 = urem i64 %v19, %v2
  br label %blk6
blk5:
  br label %blk6
blk6:
  %v18 = phi i64 [ %v20, %divok15 ], [ %v6, %blk5 ]
  %t16 = call {i64, i1} @llvm.umul.with.overflow.i64(i64 %v7, i64 %v7)
  %v21 = extractvalue {i64, i1} %t16, 0
  %ovf17 = extractvalue {i64, i1} %t16, 1
  br i1 %ovf17, label %trap18, label %ok19
trap18:
  call void @llvm.trap()
  unreachable
ok19:
  %divzero20 = icmp eq i64 %v2, 0
  br i1 %divzero20, label %divtrap21, label %divok22
divtrap21:
  call void @llvm.trap()
  unreachable
divok22:
  %v22 = urem i64 %v21, %v2
  %v23 = add i64 2, 0
  %divzero23 = icmp eq i64 %v23, 0
  br i1 %divzero23, label %divtrap24, label %divok25
divtrap24:
  call void @llvm.trap()
  unreachable
divok25:
  %v24 = udiv i64 %v8, %v23
  br label %blk1
blk3:
  %v11 = phi i64 [ %v6, %blk1 ]
  %v12 = phi i64 [ %v7, %blk1 ]
  %v13 = phi i64 [ %v8, %blk1 ]
  ret i64 %v11
}

define i64 @lcm(i64 %v0, i64 %v1) #0 {
entry:
  %v2 = add i64 0, 0
  %v3 = icmp eq i64 %v0, %v2
  br i1 %v3, label %blk1, label %blk2
blk1:
  %v4 = add i64 0, 0
  ret i64 %v4
blk2:
  %v5 = add i64 0, 0
  %v6 = icmp eq i64 %v1, %v5
  br i1 %v6, label %blk4, label %blk5
blk4:
  %v7 = add i64 0, 0
  ret i64 %v7
blk5:
  %v8 = call i64 @gcd(i64 %v0, i64 %v1)
  %divzero0 = icmp eq i64 %v8, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v9 = udiv i64 %v0, %v8
  %t3 = call {i64, i1} @llvm.umul.with.overflow.i64(i64 %v9, i64 %v1)
  %v10 = extractvalue {i64, i1} %t3, 0
  %ovf4 = extractvalue {i64, i1} %t3, 1
  br i1 %ovf4, label %trap5, label %ok6
trap5:
  call void @llvm.trap()
  unreachable
ok6:
  ret i64 %v10
}

define i64 @sumProperDivisors(i64 %v0) #0 {
entry:
  %v1 = add i64 0, 0
  %v2 = add i64 1, 0
  br label %blk1
blk1:
  %v3 = phi i64 [ %v1, %entry ], [ %v11, %ok10 ]
  %v4 = phi i64 [ %v2, %entry ], [ %v14, %ok10 ]
  %v5 = icmp ult i64 %v4, %v0
  br i1 %v5, label %blk2, label %blk3
blk2:
  %divzero0 = icmp eq i64 %v4, 0
  br i1 %divzero0, label %divtrap1, label %divok2
divtrap1:
  call void @llvm.trap()
  unreachable
divok2:
  %v8 = urem i64 %v0, %v4
  %v9 = add i64 0, 0
  %v10 = icmp eq i64 %v8, %v9
  br i1 %v10, label %blk4, label %blk5
blk4:
  %t3 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v3, i64 %v4)
  %v12 = extractvalue {i64, i1} %t3, 0
  %ovf4 = extractvalue {i64, i1} %t3, 1
  br i1 %ovf4, label %trap5, label %ok6
trap5:
  call void @llvm.trap()
  unreachable
ok6:
  br label %blk6
blk5:
  br label %blk6
blk6:
  %v11 = phi i64 [ %v12, %ok6 ], [ %v3, %blk5 ]
  %v13 = add i64 1, 0
  %t7 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v4, i64 %v13)
  %v14 = extractvalue {i64, i1} %t7, 0
  %ovf8 = extractvalue {i64, i1} %t7, 1
  br i1 %ovf8, label %trap9, label %ok10
trap9:
  call void @llvm.trap()
  unreachable
ok10:
  br label %blk1
blk3:
  %v6 = phi i64 [ %v3, %blk1 ]
  %v7 = phi i64 [ %v4, %blk1 ]
  ret i64 %v6
}

attributes #0 = { nounwind }
