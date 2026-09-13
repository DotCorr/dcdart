; /Users/ghostportal/Documents/Codex/2026-09-13/referenced-chatgpt-conversation-this-is-an/work/dcdart/core/examples/demo-collatz/collatz.dart — emitted by core/backend, not hand-written

target triple = "wasm32-unknown-unknown"

@dc_heap = global [12 x [65536 x i8]] zeroinitializer
@dc_heap_bump = global [12 x i64] zeroinitializer
@dc_heap_free = global [12 x ptr] zeroinitializer
@dc_heap_live = global i64 0
@dc_heap_sizes = constant [12 x i64] [i64 32, i64 64, i64 128, i64 256, i64 512, i64 1024, i64 2048, i64 4096, i64 8192, i64 16384, i64 32768, i64 65536]

declare void @llvm.trap()
declare {i64, i1} @llvm.uadd.with.overflow.i64(i64, i64)

define i64 @collatzSteps(i64 %v0) #0 {
entry:
  %v1 = add i64 0, 0
  br label %blk1
blk1:
  %v2 = phi i64 [ %v0, %entry ], [ %v12, %ok15 ]
  %v3 = phi i64 [ %v1, %entry ], [ %v20, %ok15 ]
  %v4 = add i64 1, 0
  %v5 = icmp ult i64 %v4, %v2
  br i1 %v5, label %blk2, label %blk3
blk2:
  %v8 = add i64 1, 0
  %v9 = and i64 %v2, %v8
  %v10 = add i64 1, 0
  %v11 = icmp ult i64 %v9, %v10
  br i1 %v11, label %blk4, label %blk5
blk4:
  %v13 = add i64 1, 0
  %v14 = lshr i64 %v2, %v13
  br label %blk6
blk5:
  %t0 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v2, i64 %v2)
  %v15 = extractvalue {i64, i1} %t0, 0
  %ovf1 = extractvalue {i64, i1} %t0, 1
  br i1 %ovf1, label %trap2, label %ok3
trap2:
  call void @llvm.trap()
  unreachable
ok3:
  %t4 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v15, i64 %v2)
  %v16 = extractvalue {i64, i1} %t4, 0
  %ovf5 = extractvalue {i64, i1} %t4, 1
  br i1 %ovf5, label %trap6, label %ok7
trap6:
  call void @llvm.trap()
  unreachable
ok7:
  %v17 = add i64 1, 0
  %t8 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v16, i64 %v17)
  %v18 = extractvalue {i64, i1} %t8, 0
  %ovf9 = extractvalue {i64, i1} %t8, 1
  br i1 %ovf9, label %trap10, label %ok11
trap10:
  call void @llvm.trap()
  unreachable
ok11:
  br label %blk6
blk6:
  %v12 = phi i64 [ %v14, %blk4 ], [ %v18, %ok11 ]
  %v19 = add i64 1, 0
  %t12 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v3, i64 %v19)
  %v20 = extractvalue {i64, i1} %t12, 0
  %ovf13 = extractvalue {i64, i1} %t12, 1
  br i1 %ovf13, label %trap14, label %ok15
trap14:
  call void @llvm.trap()
  unreachable
ok15:
  br label %blk1
blk3:
  %v6 = phi i64 [ %v2, %blk1 ]
  %v7 = phi i64 [ %v3, %blk1 ]
  ret i64 %v7
}

define i64 @sumCollatzSteps(i64 %v0) #0 {
entry:
  %v2 = add i64 0, 0
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
  %v1 = getelementptr i8, ptr %block14, i64 16
  %v3 = getelementptr i8, ptr %v1, i64 0
  store i64 %v2, ptr %v3, align 1
  %v4 = add i64 1, 0
  br label %blk1
blk1:
  %v5 = phi i64 [ %v4, %allocCont4 ], [ %v16, %ok30 ]
  %v6 = add i64 1, 0
  %t19 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v0, i64 %v6)
  %v7 = extractvalue {i64, i1} %t19, 0
  %ovf20 = extractvalue {i64, i1} %t19, 1
  br i1 %ovf20, label %trap21, label %ok22
trap21:
  call void @llvm.trap()
  unreachable
ok22:
  %v8 = icmp ult i64 %v5, %v7
  br i1 %v8, label %blk2, label %blk3
blk2:
  %v10 = getelementptr i8, ptr %v1, i64 0
  %v11 = getelementptr i8, ptr %v1, i64 0
  %v12 = load i64, ptr %v11, align 1
  %v13 = call i64 @collatzSteps(i64 %v5)
  %t23 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v12, i64 %v13)
  %v14 = extractvalue {i64, i1} %t23, 0
  %ovf24 = extractvalue {i64, i1} %t23, 1
  br i1 %ovf24, label %trap25, label %ok26
trap25:
  call void @llvm.trap()
  unreachable
ok26:
  store i64 %v14, ptr %v10, align 1
  %v15 = add i64 1, 0
  %t27 = call {i64, i1} @llvm.uadd.with.overflow.i64(i64 %v5, i64 %v15)
  %v16 = extractvalue {i64, i1} %t27, 0
  %ovf28 = extractvalue {i64, i1} %t27, 1
  br i1 %ovf28, label %trap29, label %ok30
trap29:
  call void @llvm.trap()
  unreachable
ok30:
  br label %blk1
blk3:
  %v9 = phi i64 [ %v5, %ok22 ]
  %v17 = getelementptr i8, ptr %v1, i64 0
  %v18 = load i64, ptr %v17, align 1
  %releasenull37 = icmp eq ptr %v1, null
  br i1 %releasenull37, label %releaseDone36, label %releaseLive38
releaseLive38:
  %hdr31 = getelementptr i8, ptr %v1, i64 -16
  %strong32 = load i32, ptr %hdr31
  %newstrong33 = sub i32 %strong32, 1
  store i32 %newstrong33, ptr %hdr31
  %iszero34 = icmp eq i32 %newstrong33, 0
  br i1 %iszero34, label %releaseFree35, label %releaseDone36
releaseFree35:
  %clsptr39 = getelementptr i8, ptr %hdr31, i64 8
  %clsval40 = load ptr, ptr %clsptr39
  %hasdtor41 = icmp ne ptr %clsval40, null
  br i1 %hasdtor41, label %releaseDtor42, label %releaseAfterDtor43
releaseDtor42:
  call void %clsval40(ptr %v1)
  br label %releaseAfterDtor43
releaseAfterDtor43:
  %weakptr44 = getelementptr i8, ptr %hdr31, i64 4
  %weakval45 = load i32, ptr %weakptr44
  %noweak46 = icmp eq i32 %weakval45, 0
  br i1 %noweak46, label %releaseFreeSlot47, label %releaseDone36
releaseFreeSlot47:
  %hdrint48 = ptrtoint ptr %hdr31 to i64
  %heapint49 = ptrtoint ptr @dc_heap to i64
  %diff50 = sub i64 %hdrint48, %heapint49
  %classidx51 = lshr i64 %diff50, 16
  %freeheadptr52 = getelementptr [12 x ptr], ptr @dc_heap_free, i64 0, i64 %classidx51
  %oldhead53 = load ptr, ptr %freeheadptr52
  store ptr %oldhead53, ptr %hdr31
  store ptr %hdr31, ptr %freeheadptr52
  %livebefore54 = load i64, ptr @dc_heap_live
  %liveafter55 = sub i64 %livebefore54, 1
  store i64 %liveafter55, ptr @dc_heap_live
  br label %releaseDone36
releaseDone36:
  ret i64 %v18
}

attributes #0 = { nounwind "no-builtins" }
