;
;  Copyright (c) 2010 The VP8 project authors. All Rights Reserved.
;
;  Use of this source code is governed by a BSD-style license
;  that can be found in the LICENSE file in the root of the source
;  tree. An additional intellectual property rights grant can be found
;  in the file PATENTS.  All contributing project authors may
;  be found in the AUTHORS file in the root of the source tree.
;


%include "vpx_ports/x86_abi_support.asm"

%define BLOCK_HEIGHT_WIDTH 4
%define VP8_FILTER_WEIGHT 128
%define VP8_FILTER_SHIFT  7


;/************************************************************************************
; Notes: filter_block1d_h6 applies a 6 tap filter horizontally to the input pixels. The
; input pixel array has output_height rows. This routine assumes that output_height is an
; even number. This function handles 8 pixels in horizontal direction, calculating ONE
; rows each iteration to take advantage of the 128 bits operations.
;*************************************************************************************/
;void vp8_filter_block1d8_h6_ssse3
;(
;    unsigned char  *src_ptr,
;    unsigned int    src_pixels_per_line,
;    unsigned char *output_ptr,
;    unsigned int    output_pitch,
;    unsigned int    output_height,
;    unsigned int    vp8_filter_index
;)
global sym(vp8_filter_block1d8_h6_ssse3)
sym(vp8_filter_block1d8_h6_ssse3):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 6
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    movsxd      rdx, DWORD PTR arg(5)   ;table index
    xor         rsi, rsi
    shl         rdx, 4

    movdqa      xmm7, [rd GLOBAL]

    lea         rax, [k0_k5 GLOBAL]
    add         rax, rdx
    mov         rdi, arg(2)             ;output_ptr

    cmp         esi, DWORD PTR [rax]
    je          vp8_filter_block1d8_h4_ssse3

    movdqa      xmm4, XMMWORD PTR [rax]         ;k0_k5
    movdqa      xmm5, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm6, XMMWORD PTR [rax+128]     ;k1_k3

    mov         rsi, arg(0)             ;src_ptr
    movsxd      rax, dword ptr arg(1)   ;src_pixels_per_line
    movsxd      rcx, dword ptr arg(4)   ;output_height

    movsxd      rdx, dword ptr arg(3)   ;output_pitch

    sub         rdi, rdx
;xmm3 free
filter_block1d8_h6_rowloop_ssse3:
    movdqu      xmm0,   XMMWORD PTR [rsi - 2]

    movdqa      xmm1, xmm0
    pshufb      xmm0, [shuf1b GLOBAL]

    movdqa      xmm2, xmm1
    pshufb      xmm1, [shuf2b GLOBAL]
    pmaddubsw   xmm0, xmm4
    pmaddubsw   xmm1, xmm5

    pshufb      xmm2, [shuf3b GLOBAL]
    add         rdi, rdx
    pmaddubsw   xmm2, xmm6

    lea         rsi,    [rsi + rax]
    dec         rcx
    paddsw      xmm0, xmm1
    paddsw      xmm0, xmm7
    paddsw      xmm0, xmm2
    psraw       xmm0, 7
    packuswb    xmm0, xmm0

    movq        MMWORD Ptr [rdi], xmm0
    jnz         filter_block1d8_h6_rowloop_ssse3

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

vp8_filter_block1d8_h4_ssse3:
    movdqa      xmm5, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm6, XMMWORD PTR [rax+128]     ;k1_k3

    movdqa      xmm3, XMMWORD PTR [shuf2b GLOBAL]
    movdqa      xmm4, XMMWORD PTR [shuf3b GLOBAL]

    mov         rsi, arg(0)             ;src_ptr

    movsxd      rax, dword ptr arg(1)   ;src_pixels_per_line
    movsxd      rcx, dword ptr arg(4)   ;output_height

    movsxd      rdx, dword ptr arg(3)   ;output_pitch

    sub         rdi, rdx
;xmm3 free
filter_block1d8_h4_rowloop_ssse3:
    movdqu      xmm0,   XMMWORD PTR [rsi - 2]

    movdqa      xmm2, xmm0
    pshufb      xmm0, xmm3 ;[shuf2b GLOBAL]
    pshufb      xmm2, xmm4 ;[shuf3b GLOBAL]

    pmaddubsw   xmm0, xmm5
    add         rdi, rdx
    pmaddubsw   xmm2, xmm6

    lea         rsi,    [rsi + rax]
    dec         rcx
    paddsw      xmm0, xmm7
    paddsw      xmm0, xmm2
    psraw       xmm0, 7
    packuswb    xmm0, xmm0

    movq        MMWORD Ptr [rdi], xmm0

    jnz         filter_block1d8_h4_rowloop_ssse3

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret
;void vp8_filter_block1d16_h6_ssse3
;(
;    unsigned char  *src_ptr,
;    unsigned int    src_pixels_per_line,
;    unsigned char  *output_ptr,
;    unsigned int    output_pitch,
;    unsigned int    output_height,
;    unsigned int    vp8_filter_index
;)
global sym(vp8_filter_block1d16_h6_ssse3)
sym(vp8_filter_block1d16_h6_ssse3):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 6
    SAVE_XMM
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    movsxd      rdx, DWORD PTR arg(5)   ;table index
    xor         rsi, rsi
    shl         rdx, 4      ;

    lea         rax, [k0_k5 GLOBAL]
    add         rax, rdx

    mov         rdi, arg(2)             ;output_ptr
    movdqa      xmm7, [rd GLOBAL]

;;
;;    cmp         esi, DWORD PTR [rax]
;;    je          vp8_filter_block1d16_h4_ssse3

    mov         rsi, arg(0)             ;src_ptr

    movdqa      xmm4, XMMWORD PTR [rax]         ;k0_k5
    movdqa      xmm5, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm6, XMMWORD PTR [rax+128]     ;k1_k3

    movsxd      rax, dword ptr arg(1)   ;src_pixels_per_line
    movsxd      rcx, dword ptr arg(4)   ;output_height
    movsxd      rdx, dword ptr arg(3)   ;output_pitch

filter_block1d16_h6_rowloop_ssse3:
    movdqu      xmm0,   XMMWORD PTR [rsi - 2]

    movdqa      xmm1, xmm0
    pshufb      xmm0, [shuf1b GLOBAL]
    movdqa      xmm2, xmm1
    pmaddubsw   xmm0, xmm4
    pshufb      xmm1, [shuf2b GLOBAL]
    pshufb      xmm2, [shuf3b GLOBAL]
    pmaddubsw   xmm1, xmm5

    movdqu      xmm3,   XMMWORD PTR [rsi + 6]

    pmaddubsw   xmm2, xmm6
    paddsw      xmm0, xmm1
    movdqa      xmm1, xmm3
    pshufb      xmm3, [shuf1b GLOBAL]
    paddsw      xmm0, xmm7
    pmaddubsw   xmm3, xmm4
    paddsw      xmm0, xmm2
    movdqa      xmm2, xmm1
    pshufb      xmm1, [shuf2b GLOBAL]
    pshufb      xmm2, [shuf3b GLOBAL]
    pmaddubsw   xmm1, xmm5
    pmaddubsw   xmm2, xmm6

    psraw       xmm0, 7
    packuswb    xmm0, xmm0
    lea         rsi,    [rsi + rax]
    paddsw      xmm3, xmm1
    paddsw      xmm3, xmm7
    paddsw      xmm3, xmm2
    psraw       xmm3, 7
    packuswb    xmm3, xmm3

    punpcklqdq  xmm0, xmm3

    movdqa      XMMWORD Ptr [rdi], xmm0

    add         rdi, rdx
    dec         rcx
    jnz         filter_block1d16_h6_rowloop_ssse3


    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

vp8_filter_block1d16_h4_ssse3:
    movdqa      xmm5, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm6, XMMWORD PTR [rax+128]     ;k1_k3

    mov         rsi, arg(0)             ;src_ptr
    movsxd      rax, dword ptr arg(1)   ;src_pixels_per_line
    movsxd      rcx, dword ptr arg(4)   ;output_height
    movsxd      rdx, dword ptr arg(3)   ;output_pitch

filter_block1d16_h4_rowloop_ssse3:
    movdqu      xmm1,   XMMWORD PTR [rsi - 2]

    movdqa      xmm2, xmm1
    pshufb      xmm1, [shuf2b GLOBAL]
    pshufb      xmm2, [shuf3b GLOBAL]
    pmaddubsw   xmm1, xmm5

    movdqu      xmm3,   XMMWORD PTR [rsi + 6]

    pmaddubsw   xmm2, xmm6
    movdqa      xmm0, xmm3
    pshufb      xmm3, [shuf3b GLOBAL]
    pshufb      xmm0, [shuf2b GLOBAL]

    paddsw      xmm1, xmm7
    paddsw      xmm1, xmm2

    pmaddubsw   xmm0, xmm5
    pmaddubsw   xmm3, xmm6

    psraw       xmm1, 7
    packuswb    xmm1, xmm1
    lea         rsi,    [rsi + rax]
    paddsw      xmm3, xmm0
    paddsw      xmm3, xmm7
    psraw       xmm3, 7
    packuswb    xmm3, xmm3

    punpcklqdq  xmm1, xmm3

    movdqa      XMMWORD Ptr [rdi], xmm1

    add         rdi, rdx
    dec         rcx
    jnz         filter_block1d16_h4_rowloop_ssse3


    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_filter_block1d4_h6_ssse3
;(
;    unsigned char  *src_ptr,
;    unsigned int    src_pixels_per_line,
;    unsigned char  *output_ptr,
;    unsigned int    output_pitch,
;    unsigned int    output_height,
;    unsigned int    vp8_filter_index
;)
global sym(vp8_filter_block1d4_h6_ssse3)
sym(vp8_filter_block1d4_h6_ssse3):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 6
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    movsxd      rdx, DWORD PTR arg(5)   ;table index
    mov         rsi, arg(0)             ;src_ptr
    shl         rdx, 4      ;

    lea         rax, [k0_k5 GLOBAL]
    add         rax, rdx
    movdqa      xmm7, [rd GLOBAL]





    movdqa      xmm4, XMMWORD PTR [rax]         ;k0_k5
    movdqa      xmm5, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm6, XMMWORD PTR [rax+128]     ;k1_k3

    mov         rdi, arg(2)             ;output_ptr
    movsxd      rax, dword ptr arg(1)   ;src_pixels_per_line
    movsxd      rcx, dword ptr arg(4)   ;output_height

    movsxd      rdx, dword ptr arg(3)   ;output_pitch

;xmm3 free
filter_block1d4_h6_rowloop_ssse3:
    movdqu      xmm0,   XMMWORD PTR [rsi - 2]

    movdqa      xmm1, xmm0
    pshufb      xmm0, [shuf1b GLOBAL]

    movdqa      xmm2, xmm1
    pshufb      xmm1, [shuf2b GLOBAL]
    pmaddubsw   xmm0, xmm4
    pshufb      xmm2, [shuf3b GLOBAL]
    pmaddubsw   xmm1, xmm5

;--
    pmaddubsw   xmm2, xmm6

    lea         rsi,    [rsi + rax]
;--
    paddsw      xmm0, xmm1
    paddsw      xmm0, xmm7
    pxor        xmm1, xmm1
    paddsw      xmm0, xmm2
    psraw       xmm0, 7
    packuswb    xmm0, xmm0

;
    punpcklbw   xmm0, xmm1

    movq        MMWORD PTR [rdi], xmm0
    add         rdi, rdx
    dec         rcx
    jnz         filter_block1d4_h6_rowloop_ssse3

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_filter_block1d16_v6_ssse3
;(
;    unsigned char *src_ptr,
;    unsigned int   src_pitch,
;    unsigned char *output_ptr,
;    unsigned int   out_pitch,
;    unsigned int   output_height,
;    unsigned int   vp8_filter_index
;)
global sym(vp8_filter_block1d16_v6_ssse3)
sym(vp8_filter_block1d16_v6_ssse3):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 6
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    movsxd      rdx, DWORD PTR arg(5)   ;table index
    xor         rsi, rsi
    shl         rdx, 4      ;

    lea         rax, [k0_k5 GLOBAL]
    add         rax, rdx

    cmp         esi, DWORD PTR [rax]
    je          vp8_filter_block1d16_v4_ssse3

    movdqa      xmm5, XMMWORD PTR [rax]         ;k0_k5
    movdqa      xmm6, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm7, XMMWORD PTR [rax+128]     ;k1_k3

    mov         rsi, arg(0)             ;src_ptr
    movsxd      rdx, DWORD PTR arg(1)   ;pixels_per_line
    mov         rdi, arg(2)             ;output_ptr

%if ABI_IS_32BIT=0
    movsxd      r8, DWORD PTR arg(3)    ;out_pitch
%endif
    mov         rax, rsi
    movsxd      rcx, DWORD PTR arg(4)   ;output_height
    add         rax, rdx


vp8_filter_block1d16_v6_ssse3_loop:
    movq        xmm1, MMWORD PTR [rsi]                  ;A
    movq        xmm2, MMWORD PTR [rsi + rdx]            ;B
    movq        xmm3, MMWORD PTR [rsi + rdx * 2]        ;C
    movq        xmm4, MMWORD PTR [rax + rdx * 2]        ;D
    movq        xmm0, MMWORD PTR [rsi + rdx * 4]        ;E

    punpcklbw   xmm2, xmm4                  ;B D
    punpcklbw   xmm3, xmm0                  ;C E

    movq        xmm0, MMWORD PTR [rax + rdx * 4]        ;F

    pmaddubsw   xmm3, xmm6
    punpcklbw   xmm1, xmm0                  ;A F
    pmaddubsw   xmm2, xmm7
    pmaddubsw   xmm1, xmm5

    paddsw      xmm2, xmm3
    paddsw      xmm2, xmm1
    paddsw      xmm2, [rd GLOBAL]
    psraw       xmm2, 7
    packuswb    xmm2, xmm2

    movq        MMWORD PTR [rdi], xmm2          ;store the results

    movq        xmm1, MMWORD PTR [rsi + 8]                  ;A
    movq        xmm2, MMWORD PTR [rsi + rdx + 8]            ;B
    movq        xmm3, MMWORD PTR [rsi + rdx * 2 + 8]        ;C
    movq        xmm4, MMWORD PTR [rax + rdx * 2 + 8]        ;D
    movq        xmm0, MMWORD PTR [rsi + rdx * 4 + 8]        ;E

    punpcklbw   xmm2, xmm4                  ;B D
    punpcklbw   xmm3, xmm0                  ;C E

    movq        xmm0, MMWORD PTR [rax + rdx * 4 + 8]        ;F
    pmaddubsw   xmm3, xmm6
    punpcklbw   xmm1, xmm0                  ;A F
    pmaddubsw   xmm2, xmm7
    pmaddubsw   xmm1, xmm5

    add         rsi,  rdx
    add         rax,  rdx
;--
;--
    paddsw      xmm2, xmm3
    paddsw      xmm2, xmm1
    paddsw      xmm2, [rd GLOBAL]
    psraw       xmm2, 7
    packuswb    xmm2, xmm2

    movq        MMWORD PTR [rdi+8], xmm2

%if ABI_IS_32BIT
    add         rdi,        DWORD PTR arg(3) ;out_pitch
%else
    add         rdi,        r8
%endif
    dec         rcx
    jnz         vp8_filter_block1d16_v6_ssse3_loop

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

vp8_filter_block1d16_v4_ssse3:
    movdqa      xmm6, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm7, XMMWORD PTR [rax+128]     ;k1_k3

    mov         rsi, arg(0)             ;src_ptr
    movsxd      rdx, DWORD PTR arg(1)   ;pixels_per_line
    mov         rdi, arg(2)             ;output_ptr

%if ABI_IS_32BIT=0
    movsxd      r8, DWORD PTR arg(3)    ;out_pitch
%endif
    mov         rax, rsi
    movsxd      rcx, DWORD PTR arg(4)   ;output_height
    add         rax, rdx

vp8_filter_block1d16_v4_ssse3_loop:
    movq        xmm2, MMWORD PTR [rsi + rdx]            ;B
    movq        xmm3, MMWORD PTR [rsi + rdx * 2]        ;C
    movq        xmm4, MMWORD PTR [rax + rdx * 2]        ;D
    movq        xmm0, MMWORD PTR [rsi + rdx * 4]        ;E

    punpcklbw   xmm2, xmm4                  ;B D
    punpcklbw   xmm3, xmm0                  ;C E

    pmaddubsw   xmm3, xmm6
    pmaddubsw   xmm2, xmm7
    movq        xmm5, MMWORD PTR [rsi + rdx + 8]            ;B
    movq        xmm1, MMWORD PTR [rsi + rdx * 2 + 8]        ;C
    movq        xmm4, MMWORD PTR [rax + rdx * 2 + 8]        ;D
    movq        xmm0, MMWORD PTR [rsi + rdx * 4 + 8]        ;E

    paddsw      xmm2, [rd GLOBAL]
    paddsw      xmm2, xmm3
    psraw       xmm2, 7
    packuswb    xmm2, xmm2

    punpcklbw   xmm5, xmm4                  ;B D
    punpcklbw   xmm1, xmm0                  ;C E

    pmaddubsw   xmm1, xmm6
    pmaddubsw   xmm5, xmm7

    movdqa      xmm4, [rd GLOBAL]
    add         rsi,  rdx
    add         rax,  rdx
;--
;--
    paddsw      xmm5, xmm1
    paddsw      xmm5, xmm4
    psraw       xmm5, 7
    packuswb    xmm5, xmm5

    punpcklqdq  xmm2, xmm5

    movdqa       XMMWORD PTR [rdi], xmm2

%if ABI_IS_32BIT
    add         rdi,        DWORD PTR arg(3) ;out_pitch
%else
    add         rdi,        r8
%endif
    dec         rcx
    jnz         vp8_filter_block1d16_v4_ssse3_loop

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_filter_block1d8_v6_ssse3
;(
;    unsigned char *src_ptr,
;    unsigned int   src_pitch,
;    unsigned char *output_ptr,
;    unsigned int   out_pitch,
;    unsigned int   output_height,
;    unsigned int   vp8_filter_index
;)
global sym(vp8_filter_block1d8_v6_ssse3)
sym(vp8_filter_block1d8_v6_ssse3):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 6
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    movsxd      rdx, DWORD PTR arg(5)   ;table index
    xor         rsi, rsi
    shl         rdx, 4      ;

    lea         rax, [k0_k5 GLOBAL]
    add         rax, rdx

    movsxd      rdx, DWORD PTR arg(1)   ;pixels_per_line
    mov         rdi, arg(2)             ;output_ptr
%if ABI_IS_32BIT=0
    movsxd      r8, DWORD PTR arg(3)    ; out_pitch
%endif
    movsxd      rcx, DWORD PTR arg(4)   ;[output_height]

    cmp         esi, DWORD PTR [rax]
    je          vp8_filter_block1d8_v4_ssse3

    movdqa      xmm5, XMMWORD PTR [rax]         ;k0_k5
    movdqa      xmm6, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm7, XMMWORD PTR [rax+128]     ;k1_k3

    mov         rsi, arg(0)             ;src_ptr

    mov         rax, rsi
    add         rax, rdx

vp8_filter_block1d8_v6_ssse3_loop:
    movq        xmm1, MMWORD PTR [rsi]                  ;A
    movq        xmm2, MMWORD PTR [rsi + rdx]            ;B
    movq        xmm3, MMWORD PTR [rsi + rdx * 2]        ;C
    movq        xmm4, MMWORD PTR [rax + rdx * 2]        ;D
    movq        xmm0, MMWORD PTR [rsi + rdx * 4]        ;E

    punpcklbw   xmm2, xmm4                  ;B D
    punpcklbw   xmm3, xmm0                  ;C E

    movq        xmm0, MMWORD PTR [rax + rdx * 4]        ;F
    movdqa      xmm4, [rd GLOBAL]

    pmaddubsw   xmm3, xmm6
    punpcklbw   xmm1, xmm0                  ;A F
    pmaddubsw   xmm2, xmm7
    pmaddubsw   xmm1, xmm5
    add         rsi,  rdx
    add         rax,  rdx
;--
;--
    paddsw      xmm2, xmm3
    paddsw      xmm2, xmm1
    paddsw      xmm2, xmm4
    psraw       xmm2, 7
    packuswb    xmm2, xmm2

    movq        MMWORD PTR [rdi], xmm2

%if ABI_IS_32BIT
    add         rdi,        DWORD PTR arg(3) ;[out_pitch]
%else
    add         rdi,        r8
%endif
    dec         rcx
    jnz         vp8_filter_block1d8_v6_ssse3_loop

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

vp8_filter_block1d8_v4_ssse3:
    movdqa      xmm6, XMMWORD PTR [rax+256]     ;k2_k4
    movdqa      xmm7, XMMWORD PTR [rax+128]     ;k1_k3
    movdqa      xmm5, [rd GLOBAL]

    mov         rsi, arg(0)             ;src_ptr

    mov         rax, rsi
    add         rax, rdx

vp8_filter_block1d8_v4_ssse3_loop:
    movq        xmm2, MMWORD PTR [rsi + rdx]            ;B
    movq        xmm3, MMWORD PTR [rsi + rdx * 2]        ;C
    movq        xmm4, MMWORD PTR [rax + rdx * 2]        ;D
    movq        xmm0, MMWORD PTR [rsi + rdx * 4]        ;E

    punpcklbw   xmm2, xmm4                  ;B D
    punpcklbw   xmm3, xmm0                  ;C E

    pmaddubsw   xmm3, xmm6
    pmaddubsw   xmm2, xmm7
    add         rsi,  rdx
    add         rax,  rdx
;--
;--
    paddsw      xmm2, xmm3
    paddsw      xmm2, xmm5
    psraw       xmm2, 7
    packuswb    xmm2, xmm2

    movq        MMWORD PTR [rdi], xmm2

%if ABI_IS_32BIT
    add         rdi,        DWORD PTR arg(3) ;[out_pitch]
%else
    add         rdi,        r8
%endif
    dec         rcx
    jnz         vp8_filter_block1d8_v4_ssse3_loop

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global sym(vp8_filter_block1d8_h6_ssse3_slow)
sym(vp8_filter_block1d8_h6_ssse3_slow):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 7
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    mov         rdx, arg(6) ;vp8_filter
    mov         rsi, arg(0) ;src_ptr

    mov         rdi, arg(1) ;output_ptr

    movsxd      rcx, dword ptr arg(4) ;output_height
    movsxd      rax, dword ptr arg(2) ;src_pixels_per_line

    movq        xmm7, [rdx]
    pxor        xmm4, xmm4
    movdqa      xmm5, XMMWORD PTR [shuf1 GLOBAL]
    movdqa      xmm6, XMMWORD PTR [shuf2 GLOBAL]

    movsxd      rdx, dword ptr arg(5) ;output_width

    punpcklqdq  xmm7, xmm7          ;copy filter constants to upper 8 bytes

filter_block1d8_h6_rowloop3_slow:
    movdqu      xmm0,   XMMWORD PTR [rsi - 2]

    lea         rsi,    [rsi + rax]

    movdqa      xmm1, xmm0
    pshufb      xmm0, XMMWORD PTR [shuf1 GLOBAL]

    movdqa      xmm2, xmm1
    pmaddubsw   xmm0, xmm7
    pshufb      xmm1, XMMWORD PTR [shuf2 GLOBAL]

    movdqa      xmm3, xmm2
    pmaddubsw   xmm1, xmm7
    pshufb      xmm2, XMMWORD PTR [shuf3 GLOBAL]

    pshufb      xmm3, XMMWORD PTR [shuf4 GLOBAL]

    pmaddubsw   xmm2, xmm7
    pmaddubsw   xmm3, xmm7
;4 cycles

    phaddsw     xmm0, xmm1
    phaddsw     xmm2, xmm3
;7 cycles
    phaddsw     xmm0, xmm2
;7 cycles


    paddsw      xmm0, [rd GLOBAL]
    psraw       xmm0, 7
    packuswb    xmm0, xmm0

;
    punpcklbw   xmm0, xmm4

    movdqa      XMMWORD Ptr [rdi], xmm0
    add         rdi, rdx
    dec         rcx
    jnz         filter_block1d8_h6_rowloop3_slow                ; next row

    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret
;void vp8_filter_block1d16_h6_ssse3
;(
;    unsigned char  *src_ptr,
;    unsigned short *output_ptr,
;    unsigned int    src_pixels_per_line,
;    unsigned int    pixel_step,
;    unsigned int    output_height,
;    unsigned int    output_width,
;    short           *vp8_filter
;)
global sym(vp8_filter_block1d16_h6_ssse3_slow)
sym(vp8_filter_block1d16_h6_ssse3_slow):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 7
    SAVE_XMM
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog
    mov         rdx, arg(6) ;vp8_filter
    mov         rsi, arg(0) ;src_ptr

    mov         rdi, arg(1) ;output_ptr

    movsxd      rcx, dword ptr arg(4) ;output_height
    movsxd      rax, dword ptr arg(2) ;src_pixels_per_line

    movq        xmm7, [rdx]
    pxor        xmm4, xmm4
    movdqa      xmm5, XMMWORD PTR [shuf1 GLOBAL]
    movdqa      xmm6, XMMWORD PTR [shuf2 GLOBAL]

    movsxd      rdx, dword ptr arg(5) ;output_width

    punpcklqdq  xmm7, xmm7          ;copy filter constants to upper 8 bytes
    sub         rdi, rdx

filter_block1d16_h6_rowloop3_slow:
    movdqu      xmm0,   XMMWORD PTR [rsi - 2]

    movdqa      xmm1, xmm0
    pshufb      xmm0, xmm5

    movdqa      xmm2, xmm1
    pmaddubsw   xmm0, xmm7
    pshufb      xmm1, xmm6

    movdqa      xmm3, xmm2
    pmaddubsw   xmm1, xmm7
    pshufb      xmm2, XMMWORD PTR [shuf3 GLOBAL]
    movdqu      xmm4,   XMMWORD PTR [rsi + 6]
    pshufb      xmm3, XMMWORD PTR [shuf4 GLOBAL]
    lea         rsi,    [rsi + rax]
    pmaddubsw   xmm2, xmm7
    phaddsw     xmm0, xmm1

    pmaddubsw   xmm3, xmm7
    movdqa      xmm1, xmm4
    pshufb      xmm4, xmm5
    movdqa      xmm5, xmm1
    pmaddubsw   xmm4, xmm7
    pshufb      xmm1, xmm6
    phaddsw     xmm2, xmm3
    pmaddubsw   xmm1, xmm7
    movdqa      xmm3, xmm5
    pshufb      xmm5, XMMWORD PTR [shuf3 GLOBAL]
    add         rdi, rdx
    pmaddubsw   xmm5, xmm7
    pshufb      xmm3, XMMWORD PTR [shuf4 GLOBAL]
    phaddsw     xmm4, xmm1
    dec         rcx
    phaddsw     xmm0, xmm2
    pmaddubsw   xmm3, xmm7


    paddsw      xmm0, [rd GLOBAL]
    psraw       xmm0, 7
    packuswb    xmm0, xmm0
    phaddsw     xmm5, xmm3
    pxor        xmm3, xmm3
    punpcklbw   xmm0, xmm3
;--
;--
;--
;--

    phaddsw     xmm4, xmm5
    movdqa      xmm5, XMMWORD PTR [shuf1 GLOBAL]
    movdqa      XMMWORD Ptr [rdi], xmm0
;--
;--
;--
;--
;--
    paddsw      xmm4, [rd GLOBAL]
    psraw       xmm4, 7
    packuswb    xmm4, xmm4
;
    punpcklbw   xmm4, xmm3

    movdqa      XMMWORD Ptr [rdi+16], xmm4

    jnz         filter_block1d16_h6_rowloop3_slow                ; next row


    ; begin epilog
    pop rdi
    pop rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

SECTION_RODATA
align 16
shuf1:
    db 0, 1, 2, 4, 3, 5, 128, 128, 1, 2, 3, 5, 4, 6, 128, 128
shuf2:
    db 2, 3, 4, 6, 5, 7, 128, 128, 3, 4, 5, 7, 6, 8, 128, 128
shuf3:
    db 4, 5, 6, 8, 7, 9, 128, 128, 5, 6, 7, 9, 8, 10, 128, 128
shuf4:
    db 6, 7, 8, 10, 9, 11, 128, 128, 7, 8, 9, 11, 10, 12, 128, 128

shuf1a:
    db 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8
shuf2a:
    db 2, 4, 3, 5, 4, 6, 5, 7, 6, 8, 7, 9, 8, 10, 9, 11
shuf3a:
    db 3, 5, 4, 6, 5, 7, 6, 8, 7, 9, 8, 10, 9, 11, 10, 12

shuf1b:
    db 0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 5, 10, 6, 11, 7, 12
shuf2b:
    db 2, 4, 3, 5, 4, 6, 5, 7, 6, 8, 7, 9, 8, 10, 9, 11
shuf3b:
    db 1, 3, 2, 4, 3, 5, 4, 6, 5, 7, 6, 8, 7, 9, 8, 10

align 16
rd:
    times 8 dw 0x40

align 16
k0_k5:
    times 8 db 0, 0             ;placeholder
    times 8 db 0, 0
    times 8 db 2, 1
    times 8 db 0, 0
    times 8 db 3, 3
    times 8 db 0, 0
    times 8 db 1, 2
    times 8 db 0, 0
k1_k3:
    times 8 db  0,    0         ;placeholder
    times 8 db  -6,  12
    times 8 db -11,  36
    times 8 db  -9,  50
    times 8 db -16,  77
    times 8 db  -6,  93
    times 8 db  -8, 108
    times 8 db  -1, 123
k2_k4:
    times 8 db 128,    0        ;placeholder
    times 8 db 123,   -1
    times 8 db 108,   -8
    times 8 db  93,   -6
    times 8 db  77,  -16
    times 8 db  50,   -9
    times 8 db  36,  -11
    times 8 db  12,   -6
