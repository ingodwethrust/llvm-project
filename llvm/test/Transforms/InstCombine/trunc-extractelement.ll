; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S -data-layout="e" | FileCheck %s --check-prefixes=ANY,LE
; RUN: opt < %s -instcombine -S -data-layout="E" | FileCheck %s --check-prefixes=ANY,BE

define i32 @shrinkExtractElt_i64_to_i32_0(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i32_0(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i32 0
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i32
; ANY-NEXT:    ret i32 [[T]]
;
  %e = extractelement <3 x i64> %x, i32 0
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i32 @shrinkExtractElt_i64_to_i32_1(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i32_1(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i32 1
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i32
; ANY-NEXT:    ret i32 [[T]]
;
  %e = extractelement <3 x i64> %x, i32 1
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i32 @shrinkExtractElt_i64_to_i32_2(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i32_2(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i32 2
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i32
; ANY-NEXT:    ret i32 [[T]]
;
  %e = extractelement <3 x i64> %x, i32 2
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i16 @shrinkExtractElt_i64_to_i16_0(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i16_0(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i16 0
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i16
; ANY-NEXT:    ret i16 [[T]]
;
  %e = extractelement <3 x i64> %x, i16 0
  %t = trunc i64 %e to i16
  ret i16 %t
}

define i16 @shrinkExtractElt_i64_to_i16_1(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i16_1(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i16 1
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i16
; ANY-NEXT:    ret i16 [[T]]
;
  %e = extractelement <3 x i64> %x, i16 1
  %t = trunc i64 %e to i16
  ret i16 %t
}

define i16 @shrinkExtractElt_i64_to_i16_2(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i16_2(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i16 2
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i16
; ANY-NEXT:    ret i16 [[T]]
;
  %e = extractelement <3 x i64> %x, i16 2
  %t = trunc i64 %e to i16
  ret i16 %t
}

; Crazy types may be ok.
define i11 @shrinkExtractElt_i33_to_11_2(<3 x i33> %x) {
; ANY-LABEL: @shrinkExtractElt_i33_to_11_2(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i33> [[X:%.*]], i16 2
; ANY-NEXT:    [[T:%.*]] = trunc i33 [[E]] to i11
; ANY-NEXT:    ret i11 [[T]]
;
  %e = extractelement <3 x i33> %x, i16 2
  %t = trunc i33 %e to i11
  ret i11 %t
}

; Do not optimize if it would result in an invalid bitcast instruction.
define i13 @shrinkExtractElt_i67_to_i13_2(<3 x i67> %x) {
; ANY-LABEL: @shrinkExtractElt_i67_to_i13_2(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i67> [[X:%.*]], i459 2
; ANY-NEXT:    [[T:%.*]] = trunc i67 [[E]] to i13
; ANY-NEXT:    ret i13 [[T]]
;
  %e = extractelement <3 x i67> %x, i459 2
  %t = trunc i67 %e to i13
  ret i13 %t
}

; Do not optimize if the bitcast instruction would be valid, but the
; transform would be wrong.
define i30 @shrinkExtractElt_i40_to_i30_1(<3 x i40> %x) {
; ANY-LABEL: @shrinkExtractElt_i40_to_i30_1(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i40> [[X:%.*]], i32 1
; ANY-NEXT:    [[T:%.*]] = trunc i40 [[E]] to i30
; ANY-NEXT:    ret i30 [[T]]
;
  %e = extractelement <3 x i40> %x, i32 1
  %t = trunc i40 %e to i30
  ret i30 %t
}

; Do not canonicalize if that would increase the instruction count.
declare void @use(i64)
define i16 @shrinkExtractElt_i64_to_i16_2_extra_use(<3 x i64> %x) {
; ANY-LABEL: @shrinkExtractElt_i64_to_i16_2_extra_use(
; ANY-NEXT:    [[E:%.*]] = extractelement <3 x i64> [[X:%.*]], i64 2
; ANY-NEXT:    call void @use(i64 [[E]])
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i16
; ANY-NEXT:    ret i16 [[T]]
;
  %e = extractelement <3 x i64> %x, i64 2
  call void @use(i64 %e)
  %t = trunc i64 %e to i16
  ret i16 %t
}

; Check to ensure PR45314 remains fixed.
define <4 x i64> @PR45314(<4 x i64> %x) {
; ANY-LABEL: @PR45314(
; ANY-NEXT:    [[E:%.*]] = extractelement <4 x i64> [[X:%.*]], i32 0
; ANY-NEXT:    [[T:%.*]] = trunc i64 [[E]] to i32
; ANY-NEXT:    [[I:%.*]] = insertelement <8 x i32> undef, i32 [[T]], i32 0
; ANY-NEXT:    [[S:%.*]] = shufflevector <8 x i32> [[I]], <8 x i32> undef, <8 x i32> zeroinitializer
; ANY-NEXT:    [[B:%.*]] = bitcast <8 x i32> [[S]] to <4 x i64>
; ANY-NEXT:    ret <4 x i64> [[B]]
;
  %e = extractelement <4 x i64> %x, i32 0
  %t = trunc i64 %e to i32
  %i = insertelement <8 x i32> undef, i32 %t, i32 0
  %s = shufflevector <8 x i32> %i, <8 x i32> undef, <8 x i32> zeroinitializer
  %b = bitcast <8 x i32> %s to <4 x i64>
  ret <4 x i64> %b
}
