;;;  First stage of smogo kernel bootloader

.section .first-stage, "awx"
.global _start
.intel_syntax noprefix
.code16

_start:
    ;; Initiliaze registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ;; Clear direction flag
    cld

    ;; Initialize stack
    mov sp, 0x7c00


;;; Check if a20 is enabled in safe mode
;;; If enabled jump to a20_activated else continue
check_a20:
    pushad
    mov edi, 0x112345           ; odd megabyte address
    mov esi, 0x012345           ; even megabyte address
    mov [esi], esi
    mov [edi], edi
    cmpsd                       ; Compare if esi and edi are equivalent
    popad
    jne a20_activated           ; If not equivalent A20 line is enabled
    ret

;;; Function: enable_a20
;;;
;;; Purpose: A20 line is the physical representation of the 21st bit
;;;          We want to have A20 line enabled to ensure that all memory can be accessed
enable_a20:
    call check_a20

;;; Enable a20 line with int15
enable_a20_bios:
    ;; INT15 support
    mov ax, 2403h
    int 15h
    jb a20_bios_after           ; INT15 not supported
    cmp ah, 0
    jnz a20_bios_after          ; INT15 not supported

    ;; A20 status
    mov ax, 2402h
    int 15h
    jb a20_bios_after           ; Couldn't get A20 status
    cmp ah, 0
    jnz a20_bios_after          ; Couldn't get A20 status

    cmp al, 1
    jz a20_activated            ; A20 is already activated

    ;; Activate A20
    mov ax, 2401h
    int 15h
    jb a20_bios_after
    cmp ah, 0
    jnz a20_bios_after
a20_bios_after:

;;; Fast a20
enable_a20_fast:
    int al, 0x92
    test al, 2
    jnz a20_fast_after
    or al, 2
    and al, 0xFE
    out 0x92, al
a20_fast_after:

a20_activated:

a20_failed:
