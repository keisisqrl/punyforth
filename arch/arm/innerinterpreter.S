/*
    Indirect threaded inner interpreter:
        - r7 forth instruction pointer
        - r0 working register
        - sp stack pointer
        - r6 rstack pointer
*/    

.macro NEXT
    ldr r0, [r7]   
    adds r7, r7, CELLS
    ldr r1, [r0]
    bx r1
.endm