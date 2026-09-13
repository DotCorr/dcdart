; /Users/ghostportal/Documents/Codex/2026-09-13/referenced-chatgpt-conversation-this-is-an/work/dcdart/core/examples/m2-recursion/recursion.dart — emitted by core/backend, not hand-written

target triple = "wasm32-unknown-unknown"

@dc_heap = global [12 x [65536 x i8]] zeroinitializer
@dc_heap_bump = global [12 x i64] zeroinitializer
@dc_heap_free = global [12 x ptr] zeroinitializer
@dc_heap_live = global i64 0
@dc_heap_sizes = constant [12 x i64] [i64 32, i64 64, i64 128, i64 256, i64 512, i64 1024, i64 2048, i64 4096, i64 8192, i64 16384, i64 32768, i64 65536]

declare void @llvm.trap()
declare {i64, i1} @llvm.uadd.with.overflow.i64(i64, i64)
declare {i64, i1} @llvm.usub.with.overflow.i64(i64, i64)

define i64 @sumBoxValues(i64 %v0) #0 {
entry:
  %v1 = add i64 1, 0
  %v2 = icmp ult i64 %v0, %v1
  br i1 %v2, label %blk1, label %blk2
blk1:
  %v3 = add i64 0, 0
  ret i64 %v3
blk2:
  %freeheadptr5 = getelementptr [12 x ptr], ptr @dc_heap_free, i64 0, i64 0
  %freehead6 = load ptr, ptr %freeheadptr5
  %isempty7 = icmp eq ptr %freehead6, null
  br i1 %isempty7, label %allocBump1, label %allocPop0
allocPop0:
  %next8 = load ptr, ptr %freehead6
  store ptr %next8, ptr %freeheadptr5
  br label %allocCont4
allocBump1:
  %bumpptr9 = getelementptr [12 x i64], ptr @dc_heap_bump, i64 0, i64 0
  %used10 = load i64, ptr %bumpptr9
  %newused11 = add i64 %used10, 32
  %over12 = icmp ugt i64 %newused11, 65536
  br i1 %over12, label %allocOom3, label %allocDoBump2
allocOom3:
  call void @llvm.trap()
  unreachable
allocDoBump2:
  store i64 %newused11, ptr %bumpptr9
  %fresh13 = getelementptr [12 x [65536 x i8]], ptr @dc_heap, i64 0, i64 0, i64 %used10
  br label %allocCont4
allocCont4:
  %block14 = phi ptr [ %freehead6, %allocPop0 ], [ %fresh13, %allocDoBump2 ]
  store i32 1, ptr %block14
  %weakptr15 = getelementptr i8, ptr %block14, i64 4
  store i32 0, ptr %weakptr15
  %clsptr16 = getelementptr i8, ptr %block14, i64 8
  store ptr null, ptr %clsptr16
  %livebefore17 = load i64, ptr @dc_heap_live
  %liveafter18 = add i64 %livebefore17, 1
  store i64 %liveafter18, ptr @dc_heap_live
  %v4 = getelementptr i8, ptr %block14, i64 16
  %v5 = getelementptr i8, ptr %v4, i64 0
  store i64 %v0, ptr %v5
  %v6 = getelementptr i8, ptr %v4, i64 0
  %v7 = load i64, ptr %v6
  %v9 = add i64 1, 0
  %t19 = call {i64, i1} @llvm.usub.with.overflow.i64(i64 %v0, i64 %v9)
  %v10 = extractvalue {i64, i1} %t19, 0
  %ovf20 = extractvalue {i64, i1} %t19, 1
  br i1 %ovf20, label %trap21, label %ok22
trap21:
  call void @llvm.trap()
  unreachable
ok22:
  %v8 = call i64 @sumBoxValues(i64 %v10)
  %t23 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v7, i64 %v8)
  %v11 = extractvalue {i64, i1} %t23, 0
  %ovf24 = extractvalue {i64, i1} %t23, 1
  br i1 %ovf24, label %trap25, label %ok26
trap25:
  call void @llvm.trap()
  unreachable
ok26:
  %releasenull33 = icmp eq ptr %v4, null
  br i1 %releasenull33, label %releaseDone32, label %releaseLive34
releaseLive34:
  %hdr27 = getelementptr i8, ptr %v4, i64 -16
  %strong28 = load i32, ptr %hdr27
  %newstrong29 = sub i32 %strong28, 1
  store i32 %newstrong29, ptr %hdr27
  %iszero30 = icmp eq i32 %newstrong29, 0
  br i1 %iszero30, label %releaseFree31, label %releaseDone32
releaseFree31:
  %clsptr35 = getelementptr i8, ptr %hdr27, i64 8
  %clsval36 = load ptr, ptr %clsptr35
  %hasdtor37 = icmp ne ptr %clsval36, null
  br i1 %hasdtor37, label %releaseDtor38, label %releaseAfterDtor39
releaseDtor38:
  call void %clsval36(ptr %v4)
  br label %releaseAfterDtor39
releaseAfterDtor39:
  %weakptr40 = getelementptr i8, ptr %hdr27, i64 4
  %weakval41 = load i32, ptr %weakptr40
  %noweak42 = icmp eq i32 %weakval41, 0
  br i1 %noweak42, label %releaseFreeSlot43, label %releaseDone32
releaseFreeSlot43:
  %hdrint44 = ptrtoint ptr %hdr27 to i64
  %heapint45 = ptrtoint ptr @dc_heap to i64
  %diff46 = sub i64 %hdrint44, %heapint45
  %classidx47 = lshr i64 %diff46, 16
  %freeheadptr48 = getelementptr [12 x ptr], ptr @dc_heap_free, i64 0, i64 %classidx47
  %oldhead49 = load ptr, ptr %freeheadptr48
  store ptr %oldhead49, ptr %hdr27
  store ptr %hdr27, ptr %freeheadptr48
  %livebefore50 = load i64, ptr @dc_heap_live
  %liveafter51 = sub i64 %livebefore50, 1
  store i64 %liveafter51, ptr @dc_heap_live
  br label %releaseDone32
releaseDone32:
  ret i64 %v11
}

attributes #0 = { nounwind "no-builtins" }
