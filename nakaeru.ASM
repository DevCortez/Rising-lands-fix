format pe gui 4.0 dll

include '%fasm%\win32ax.inc'

section 'code' code readable executable writeable

; Consts
  PrimarySurface = 4E178Ch

; Nopes

;1
;00474B70  |. 74 3F          JE SHORT RISING_V.00474BB1 <--- Removes cd verification

; Patches

;1
;0043F2E8                   |. FF52 1C        |CALL DWORD PTR DS:[EDX+1C]                                     ;  Copy data from backBuffer to primary surface
;0043F2EB                   |. 89C2           |MOV EDX,EAX
;0043F2ED                   |. 85C0           |TEST EAX,EAX

;2 Adjusted file loading to load properly
;0048CB32 <LoadFileProc>   /$ 53             PUSH EBX <--- hax [ESP] for file path
;0048CB33                  |. 51             PUSH ECX
;0048CB34                  |. 52             PUSH EDX
;0048CB35                  |. 56             PUSH ESI
;0048CB36                  |. 57             PUSH EDI
;0048CB37                  |. 55             PUSH EBP <--- returns here
;0048CB38                  |. 83EC 0C        SUB ESP,0C

;5 Speed fix
;0046009B                        . E8 984E0100    CALL <RISING.DrawScreen> <--- Hook here
;004600A0                        . EB 07          JMP SHORT RISING.004600A9 <--- Return here


p1a dd 0043F2E8h
p1r dd 0043F2EDh

p2a dd 48CB32h
p2r dd 48CB37h

p3a dd 00474F88h
p3r dd 00474F8Dh

p4a dd 0042C94Fh
p4r dd 0042D589h

p5a dd 46009Bh
p5r dd 4600A0h


start:
  ;Nopify
  invoke VirtualProtect, 474B70h, 2, PAGE_EXECUTE_READWRITE, placeHolder
  mov word [474B70h], 0x9090

  ;Start patching

  ; This one is crapped so far
  ;invoke VirtualProtect, [p1a], 5, PAGE_EXECUTE_READWRITE, placeHolder
  ;mov eax, [p1a]
  ;mov byte [eax], 0xE9
  ;mov ecx, patch_1
  ;sub ecx, eax
  ;sub ecx, 5
  ;mov dword [eax+1], ecx

  invoke VirtualProtect, [p2a], 5, PAGE_EXECUTE_READWRITE, placeHolder
  mov eax, [p2a]
  mov byte [eax], 0xE9
  mov ecx, patch_2
  sub ecx, eax
  sub ecx, 5
  mov dword [eax+1], ecx

  invoke VirtualProtect, [p5a], 5, PAGE_EXECUTE_READWRITE, placeHolder
  mov eax, [p5a]
  mov byte [eax], 0xE9
  mov ecx, patch_5
  sub ecx, eax
  sub ecx, 5
  mov dword [eax+1], ecx

  or al, 1
  retn

placeHolder dd 0

patch_1:
  ; Blt interface
  CALL DWORD [EDX+1Ch] ;44h = GetDC 68h = ReleaseDC

  pushad

  ; Get diBits and transform it properly to display
  push surfaceDC
  mov eax, [PrimarySurface]
  mov edx, [eax]
  push eax
  call dword [edx+44h]
  test eax, eax
  je patch_1_abort
    db $cc
    invoke FindWindowA, 0, 'Rising Lands'
    mov [windowHandle], eax
    invoke GetDC, eax
    mov [windowDC], eax
    invoke CreateCompatibleDC, [surfaceDC]
    mov [compatibleDC], eax
    invoke CreateCompatibleDC, [windowDC]
    mov [compatibleWindowDC], eax
    invoke CreateCompatibleBitmap, [windowDC], 800, 600
    mov [zbitmap], eax

    invoke GetDIBits, [compatibleWindowDC], [zbitmap], 0, 0, 0, bitmapHeader, 0
    test eax, eax
    jnz @f
      invoke MessageBoxA, 0, 'Failed to get dibits', 0, 0
    @@:

    invoke GetDIBits, [compatibleDC], [zbitmap], 0, 600, pixelDump, bitmapHeader, 0
    test eax, eax
    jnz @f
      invoke MessageBoxA, 0, 'Failed second call to dibits', 0, 0
    @@:

    invoke SetDIBits, [compatibleWindowDC], [zbitmap], 0, 600, pixelDump, bitmapHeader, 0
    test eax, eax
    jnz @f
      invoke MessageBoxA, 0, 'Setdibs fuckedup our life', 0, 0
    @@:

    ; Release
    push [surfaceDC]
    mov eax, [PrimarySurface]
    mov edx, [eax]
    push eax
    call dword [edx+68h]

  patch_1_abort:
  popad

  ; Original code finalization
  MOV EDX,EAX
  TEST EAX, EAX
  jmp [p1r]

  ; Vars
  surfaceDC dd 0
  windowHandle dd 0
  windowDC dd 0
  compatibleDC dd 0
  compatibleWindowDC dd 0
  zbitmap dd 0


  ; Buffers
  bitmapInfo dd bitmapHeader
  dd 0

  bitmapHeader:
  hSize dd endHeader - bitmapHeader
  hWidth dd 0;800
  hHeight dd 0;600
  hPlanes dw 0;1
  hBitCount dw 0;32
  hCompression dd 0
  hSizeImage dd 0
  hxPPm dd 0
  hyPPm dd 0
  hClrUsed dd 0
  hClrImp dd 0
  endHeader:

  pixelDump rb 800*600*10


patch_2:
  pushad
  mov eax, [esp+4*8 + 4]
  invoke CreateFileA, eax, GENERIC_READ, 0, 0, OPEN_ALWAYS, 0, 0
  cmp eax, -1
  jne @f
    invoke GetCurrentDirectoryA, 2047, p2buffer

    xor ecx, ecx
    dec ecx
    mov edi, [esp+4*8 + 4]
    xor al, al
    repne scasb
    neg ecx
    push ecx

    xor ecx, ecx
    dec ecx
    mov edi, p2buffer
    xor al, al
    repne scasb
    pop ecx
    dec edi
    mov byte [edi], '\'
    inc edi
    mov esi, [esp+4*8 + 4]
    inc esi
    inc esi
    rep movsb
    mov dword [esp+4*8 + 4], p2buffer

  @@:
  invoke CloseHandle, eax
  ; Original code
  popad
  PUSH EBX
  PUSH ECX
  PUSH EDX
  PUSH ESI
  PUSH EDI
  jmp [p2r]

  p2buffer rb 3048


patch_5:
  pushad
    @@:
    invoke GetTickCount
    sub eax, [timeStamp]
    cmp eax, 1000 / 90
    jb @b
    invoke GetTickCount
    mov [timeStamp], eax
  popad
  CALL [drawCall]
  jmp [p5r]

  timeStamp dd 0
  drawCall dd 00474F38h

; Special patches

; Resolution patch
;0043F5BB                        . 74 25          JE SHORT RISING.0043F5E2
;0043F5BD                        . BF 20030000    MOV EDI,320
;0043F5C2                        . B8 58020000    MOV EAX,258
;0043F5C7                        . BA 11000000    MOV EDX,11
;0043F5CC                        . 66:893D 18A049>MOV WORD PTR DS:[49A018],DI
;0043F5D3                        . 66:A3 1AA04900 MOV WORD PTR DS:[49A01A],AX
;0043F5D9                        . 66:8915 168750>MOV WORD PTR DS:[508716],DX
;0043F5E0                        . EB 24          JMP SHORT RISING.0043F606





; Window mode patch



; Windowed

.end start

section 'fxup' fixups readable