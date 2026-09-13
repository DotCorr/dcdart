; /Users/ghostportal/Documents/Codex/2026-09-13/referenced-chatgpt-conversation-this-is-an/work/dcdart/core/examples/m4-float-arith/floatarith.dart — emitted by core/backend, not hand-written

target triple = "wasm32-unknown-unknown"

declare i32 @llvm.fptoui.sat.i32.float(float)
declare i64 @llvm.fptoui.sat.i64.double(double)
declare void @llvm.trap()
declare {i64, i1} @llvm.uadd.with.overflow.i64(i64, i64)

define double @addF64(double %v0, double %v1) #0 {
entry:
  %v2 = fadd double %v0, %v1
  ret double %v2
}

define double @subF64(double %v0, double %v1) #0 {
entry:
  %v2 = fsub double %v0, %v1
  ret double %v2
}

define double @mulF64(double %v0, double %v1) #0 {
entry:
  %v2 = fmul double %v0, %v1
  ret double %v2
}

define double @divF64(double %v0, double %v1) #0 {
entry:
  %v2 = fdiv double %v0, %v1
  ret double %v2
}

define float @addF32(float %v0, float %v1) #0 {
entry:
  %v2 = fadd float %v0, %v1
  ret float %v2
}

define float @subF32(float %v0, float %v1) #0 {
entry:
  %v2 = fsub float %v0, %v1
  ret float %v2
}

define float @mulF32(float %v0, float %v1) #0 {
entry:
  %v2 = fmul float %v0, %v1
  ret float %v2
}

define float @divF32(float %v0, float %v1) #0 {
entry:
  %v2 = fdiv float %v0, %v1
  ret float %v2
}

define double @negF64(double %v0) #0 {
entry:
  %v1 = fneg double %v0
  ret double %v1
}

define float @negF32(float %v0) #0 {
entry:
  %v1 = fneg float %v0
  ret float %v1
}

define i64 @ltF64(double %v0, double %v1) #0 {
entry:
  %v2 = fcmp olt double %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define i64 @leF64(double %v0, double %v1) #0 {
entry:
  %v2 = fcmp ole double %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define i64 @gtF64(double %v0, double %v1) #0 {
entry:
  %v2 = fcmp ogt double %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define i64 @geF64(double %v0, double %v1) #0 {
entry:
  %v2 = fcmp oge double %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define i64 @eqF64(double %v0, double %v1) #0 {
entry:
  %v2 = fcmp oeq double %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define i64 @neF64(double %v0, double %v1) #0 {
entry:
  %v2 = fcmp une double %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define i64 @ltF32(float %v0, float %v1) #0 {
entry:
  %v2 = fcmp olt float %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 1, 0
  ret i64 %v3
blk2:
  %v4 = add i64 0, 0
  ret i64 %v4
}

define double @literalF64() #0 {
entry:
  %v0 = bitcast i64 4614256656552045848 to double
  ret double %v0
}

define float @literalF32() #0 {
entry:
  %v0 = bitcast i32 1036831949 to float
  ret float %v0
}

define double @literalFromInt() #0 {
entry:
  %v0 = bitcast i64 4611686018427387904 to double
  ret double %v0
}

define double @widen(float %v0) #0 {
entry:
  %v1 = fpext float %v0 to double
  ret double %v1
}

define float @narrow(double %v0) #0 {
entry:
  %v1 = fptrunc double %v0 to float
  ret float %v1
}

define float @u32ToF32(i32 %v0) #0 {
entry:
  %v1 = uitofp i32 %v0 to float
  ret float %v1
}

define double @u64ToF64(i64 %v0) #0 {
entry:
  %v1 = uitofp i64 %v0 to double
  ret double %v1
}

define i32 @truncF32(float %v0) #0 {
entry:
  %v1 = call i32 @llvm.fptoui.sat.i32.float(float %v0)
  ret i32 %v1
}

define i64 @truncF64(double %v0) #0 {
entry:
  %v1 = call i64 @llvm.fptoui.sat.i64.double(double %v0)
  ret i64 %v1
}

define double @horner4(double %v0) #0 {
entry:
  %v1 = bitcast i64 4607182418800017408 to double
  %v2 = bitcast i64 4627448617123184640 to double
  %v3 = fdiv double %v1, %v2
  %v4 = fmul double %v3, %v0
  %v5 = bitcast i64 4607182418800017408 to double
  %v6 = bitcast i64 4618441417868443648 to double
  %v7 = fdiv double %v5, %v6
  %v8 = fadd double %v4, %v7
  %v9 = fmul double %v8, %v0
  %v10 = bitcast i64 4602678819172646912 to double
  %v11 = fadd double %v9, %v10
  %v12 = fmul double %v11, %v0
  %v13 = bitcast i64 4607182418800017408 to double
  %v14 = fadd double %v12, %v13
  %v15 = fmul double %v14, %v0
  %v16 = bitcast i64 4607182418800017408 to double
  %v17 = fadd double %v15, %v16
  ret double %v17
}

define double @geomSum(i64 %v0, double %v1) #0 {
entry:
  %v2 = bitcast i64 0 to double
  %v3 = bitcast i64 4607182418800017408 to double
  %v4 = add i64 0, 0
  br label %blk1
blk1:
  %v5 = phi double [ %v2, %entry ], [ %v12, %ok3 ]
  %v6 = phi double [ %v3, %entry ], [ %v13, %ok3 ]
  %v7 = phi i64 [ %v4, %entry ], [ %v15, %ok3 ]
  %v8 = icmp ult i64 %v7, %v0
  br i1 %v8, label %blk2, label %blk3
blk2:
  %v12 = fadd double %v5, %v6
  %v13 = fmul double %v6, %v1
  %v14 = add i64 1, 0
  %t0 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v7, i64 %v14)
  %v15 = extractvalue {i64, i1} %t0, 0
  %ovf1 = extractvalue {i64, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  br label %blk1
blk3:
  %v9 = phi double [ %v5, %blk1 ]
  %v10 = phi double [ %v6, %blk1 ]
  %v11 = phi i64 [ %v7, %blk1 ]
  ret double %v9
}

attributes #0 = { nounwind }
