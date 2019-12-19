; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=arm64-eabi -aarch64-neon-syntax=apple | FileCheck %s --check-prefixes=CHECK,GENERIC
; RUN: llc < %s -O0 -fast-isel -mtriple=arm64-eabi -aarch64-neon-syntax=apple | FileCheck %s --check-prefixes=CHECK,FAST
; RUN: llc < %s -global-isel -global-isel-abort=2 -pass-remarks-missed=gisel* \
; RUN:          -mtriple=arm64-eabi -aarch64-neon-syntax=apple \
; RUN:          | FileCheck %s --check-prefixes=GISEL,FALLBACK

; FALLBACK-NOT: remark{{.*}}G_FPEXT{{.*}}(in function: test_vcvt_f64_f32)
; FALLBACK-NOT: remark{{.*}}fpext{{.*}}(in function: test_vcvt_f64_f32)
define <2 x double> @test_vcvt_f64_f32(<2 x float> %x) nounwind readnone ssp {
; CHECK-LABEL: test_vcvt_f64_f32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    fcvtl v0.2d, v0.2s
; CHECK-NEXT:    ret
;
; GISEL-LABEL: test_vcvt_f64_f32:
; GISEL:       // %bb.0:
; GISEL-NEXT:    fcvtl v0.2d, v0.2s
; GISEL-NEXT:    ret
  %vcvt1.i = fpext <2 x float> %x to <2 x double>
  ret <2 x double> %vcvt1.i
}

; FALLBACK-NOT: remark{{.*}}G_FPEXT{{.*}}(in function: test_vcvt_high_f64_f32)
; FALLBACK-NOT: remark{{.*}}fpext{{.*}}(in function: test_vcvt_high_f64_f32)
define <2 x double> @test_vcvt_high_f64_f32(<4 x float> %x) nounwind readnone ssp {
; CHECK-LABEL: test_vcvt_high_f64_f32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    fcvtl2 v0.2d, v0.4s
; CHECK-NEXT:    ret
;
; GISEL-LABEL: test_vcvt_high_f64_f32:
; GISEL:       // %bb.0:
; GISEL-NEXT:    fcvtl2 v0.2d, v0.4s
; GISEL-NEXT:    ret
  %cvt_in = shufflevector <4 x float> %x, <4 x float> undef, <2 x i32> <i32 2, i32 3>
  %vcvt1.i = fpext <2 x float> %cvt_in to <2 x double>
  ret <2 x double> %vcvt1.i
}

define <2 x double> @test_vcvt_high_f64_f32_bitcast(<4 x float> %x) nounwind readnone ssp {
; GENERIC-LABEL: test_vcvt_high_f64_f32_bitcast:
; GENERIC:       // %bb.0:
; GENERIC-NEXT:    ext.16b v0, v0, v0, #8
; GENERIC-NEXT:    fcvtl v0.2d, v0.2s
; GENERIC-NEXT:    ret
;
; FAST-LABEL: test_vcvt_high_f64_f32_bitcast:
; FAST:       // %bb.0:
; FAST-NEXT:    fcvtl2 v0.2d, v0.4s
; FAST-NEXT:    ret
;
; GISEL-LABEL: test_vcvt_high_f64_f32_bitcast:
; GISEL:       // %bb.0:
; GISEL-NEXT:    ext.16b v0, v0, v0, #8
; GISEL-NEXT:    fcvtl v0.2d, v0.2s
; GISEL-NEXT:    ret
  %bc1 = bitcast <4 x float> %x to <2 x double>
  %ext = shufflevector <2 x double> %bc1, <2 x double> undef, <1 x i32> <i32 1>
  %bc2 = bitcast <1 x double> %ext to <2 x float>
  %r = fpext <2 x float> %bc2 to <2 x double>
  ret <2 x double> %r
}

define <2 x double> @test_vcvt_high_i64_f32_bitcast(<2 x i64> %x) nounwind readnone ssp {
; GENERIC-LABEL: test_vcvt_high_i64_f32_bitcast:
; GENERIC:       // %bb.0:
; GENERIC-NEXT:    ext.16b v0, v0, v0, #8
; GENERIC-NEXT:    fcvtl v0.2d, v0.2s
; GENERIC-NEXT:    ret
;
; FAST-LABEL: test_vcvt_high_i64_f32_bitcast:
; FAST:       // %bb.0:
; FAST-NEXT:    ext.16b v0, v0, v0, #8
; FAST-NEXT:    // kill: def $d0 killed $d0 killed $q0
; FAST-NEXT:    fcvtl v0.2d, v0.2s
; FAST-NEXT:    ret
;
; GISEL-LABEL: test_vcvt_high_i64_f32_bitcast:
; GISEL:       // %bb.0:
; GISEL-NEXT:    ext.16b v0, v0, v0, #8
; GISEL-NEXT:    fcvtl v0.2d, v0.2s
; GISEL-NEXT:    ret
  %ext = shufflevector <2 x i64> %x, <2 x i64> undef, <1 x i32> <i32 1>
  %bc2 = bitcast <1 x i64> %ext to <2 x float>
  %r = fpext <2 x float> %bc2 to <2 x double>
  ret <2 x double> %r
}

; FALLBACK-NOT: remark{{.*}}G_FPEXT{{.*}}(in function: test_vcvt_f32_f64)
; FALLBACK-NOT: remark{{.*}}fpext{{.*}}(in function: test_vcvt_f32_f64)
define <2 x float> @test_vcvt_f32_f64(<2 x double> %v) nounwind readnone ssp {
; CHECK-LABEL: test_vcvt_f32_f64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    fcvtn v0.2s, v0.2d
; CHECK-NEXT:    ret
;
; GISEL-LABEL: test_vcvt_f32_f64:
; GISEL:       // %bb.0:
; GISEL-NEXT:    fcvtn v0.2s, v0.2d
; GISEL-NEXT:    ret
  %vcvt1.i = fptrunc <2 x double> %v to <2 x float>
  ret <2 x float> %vcvt1.i
}

; FALLBACK-NOT: remark{{.*}}G_FPEXT{{.*}}(in function: test_vcvt_high_f32_f64)
; FALLBACK-NOT: remark{{.*}}fpext{{.*}}(in function: test_vcvt_high_f32_f64)
define <4 x float> @test_vcvt_high_f32_f64(<2 x float> %x, <2 x double> %v) nounwind readnone ssp {
; GENERIC-LABEL: test_vcvt_high_f32_f64:
; GENERIC:       // %bb.0:
; GENERIC-NEXT:    // kill: def $d0 killed $d0 def $q0
; GENERIC-NEXT:    fcvtn2 v0.4s, v1.2d
; GENERIC-NEXT:    ret
;
; FAST-LABEL: test_vcvt_high_f32_f64:
; FAST:       // %bb.0:
; FAST-NEXT:    // implicit-def: $q2
; FAST-NEXT:    mov.16b v2, v0
; FAST-NEXT:    fcvtn2 v2.4s, v1.2d
; FAST-NEXT:    mov.16b v0, v2
; FAST-NEXT:    ret
;
; GISEL-LABEL: test_vcvt_high_f32_f64:
; GISEL:       // %bb.0:
; GISEL-NEXT:    // kill: def $d0 killed $d0 def $q0
; GISEL-NEXT:    fcvtn2 v0.4s, v1.2d
; GISEL-NEXT:    ret
  %cvt = fptrunc <2 x double> %v to <2 x float>
  %vcvt2.i = shufflevector <2 x float> %x, <2 x float> %cvt, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret <4 x float> %vcvt2.i
}

define <2 x float> @test_vcvtx_f32_f64(<2 x double> %v) nounwind readnone ssp {
; CHECK-LABEL: test_vcvtx_f32_f64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    fcvtxn v0.2s, v0.2d
; CHECK-NEXT:    ret
;
; GISEL-LABEL: test_vcvtx_f32_f64:
; GISEL:       // %bb.0:
; GISEL-NEXT:    fcvtxn v0.2s, v0.2d
; GISEL-NEXT:    ret
  %vcvtx1.i = tail call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %v) nounwind
  ret <2 x float> %vcvtx1.i
}

define <4 x float> @test_vcvtx_high_f32_f64(<2 x float> %x, <2 x double> %v) nounwind readnone ssp {
; GENERIC-LABEL: test_vcvtx_high_f32_f64:
; GENERIC:       // %bb.0:
; GENERIC-NEXT:    // kill: def $d0 killed $d0 def $q0
; GENERIC-NEXT:    fcvtxn2 v0.4s, v1.2d
; GENERIC-NEXT:    ret
;
; FAST-LABEL: test_vcvtx_high_f32_f64:
; FAST:       // %bb.0:
; FAST-NEXT:    // implicit-def: $q2
; FAST-NEXT:    mov.16b v2, v0
; FAST-NEXT:    fcvtxn2 v2.4s, v1.2d
; FAST-NEXT:    mov.16b v0, v2
; FAST-NEXT:    ret
;
; GISEL-LABEL: test_vcvtx_high_f32_f64:
; GISEL:       // %bb.0:
; GISEL-NEXT:    // kill: def $d0 killed $d0 def $q0
; GISEL-NEXT:    fcvtxn2 v0.4s, v1.2d
; GISEL-NEXT:    ret
  %vcvtx2.i = tail call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %v) nounwind
  %res = shufflevector <2 x float> %x, <2 x float> %vcvtx2.i, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret <4 x float> %res
}


declare <2 x double> @llvm.aarch64.neon.vcvthighfp2df(<4 x float>) nounwind readnone
declare <2 x double> @llvm.aarch64.neon.vcvtfp2df(<2 x float>) nounwind readnone

declare <2 x float> @llvm.aarch64.neon.vcvtdf2fp(<2 x double>) nounwind readnone
declare <4 x float> @llvm.aarch64.neon.vcvthighdf2fp(<2 x float>, <2 x double>) nounwind readnone

declare <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double>) nounwind readnone

define i16 @to_half(float %in) {
; GENERIC-LABEL: to_half:
; GENERIC:       // %bb.0:
; GENERIC-NEXT:    fcvt h0, s0
; GENERIC-NEXT:    fmov w0, s0
; GENERIC-NEXT:    ret
;
; FAST-LABEL: to_half:
; FAST:       // %bb.0:
; FAST-NEXT:    sub sp, sp, #16 // =16
; FAST-NEXT:    .cfi_def_cfa_offset 16
; FAST-NEXT:    fcvt h1, s0
; FAST-NEXT:    // implicit-def: $w0
; FAST-NEXT:    fmov s0, w0
; FAST-NEXT:    mov.16b v0, v1
; FAST-NEXT:    fmov w8, s0
; FAST-NEXT:    mov w0, w8
; FAST-NEXT:    str w0, [sp, #12] // 4-byte Folded Spill
; FAST-NEXT:    mov w0, w8
; FAST-NEXT:    add sp, sp, #16 // =16
; FAST-NEXT:    ret
;
; GISEL-LABEL: to_half:
; GISEL:       // %bb.0:
; GISEL-NEXT:    fcvt h0, s0
; GISEL-NEXT:    fmov w0, s0
; GISEL-NEXT:    ret
  %res = call i16 @llvm.convert.to.fp16.f32(float %in)
  ret i16 %res
}

define float @from_half(i16 %in) {
; GENERIC-LABEL: from_half:
; GENERIC:       // %bb.0:
; GENERIC-NEXT:    fmov s0, w0
; GENERIC-NEXT:    fcvt s0, h0
; GENERIC-NEXT:    ret
;
; FAST-LABEL: from_half:
; FAST:       // %bb.0:
; FAST-NEXT:    fmov s0, w0
; FAST-NEXT:    // kill: def $h0 killed $h0 killed $s0
; FAST-NEXT:    fcvt s0, h0
; FAST-NEXT:    ret
;
; GISEL-LABEL: from_half:
; GISEL:       // %bb.0:
; GISEL-NEXT:    fmov s0, w0
; GISEL-NEXT:    fcvt s0, h0
; GISEL-NEXT:    ret
  %res = call float @llvm.convert.from.fp16.f32(i16 %in)
  ret float %res
}

declare float @llvm.convert.from.fp16.f32(i16) #1
declare i16 @llvm.convert.to.fp16.f32(float) #1
