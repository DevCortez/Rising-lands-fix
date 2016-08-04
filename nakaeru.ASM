format pe gui 4.0 dll

include '%fasm%\win32ax.inc'

section 'code' code readable executable writeable

; Consts
  PrimarySurface = 4E178Ch

; Nopes

;1
;00474B70  |. 74 3F	     JE SHORT RISING_V.00474BB1 <--- Removes cd verification

; Patches

;1
;0043F2E8		    |. FF52 1C	      |CALL DWORD PTR DS:[EDX+1C]				      ;  Copy data from backBuffer to primary surface
;0043F2EB		    |. 89C2	      |MOV EDX,EAX
;0043F2ED		    |. 85C0	      |TEST EAX,EAX




;2 Adjusted file loading to load properly
;0048CB32 <LoadFileProc>   /$ 53	     PUSH EBX <--- hax [ESP] for file path
;0048CB33		   |. 51	     PUSH ECX
;0048CB34		   |. 52	     PUSH EDX
;0048CB35		   |. 56	     PUSH ESI
;0048CB36		   |. 57	     PUSH EDI
;0048CB37		   |. 55	     PUSH EBP <--- returns here
;0048CB38		   |. 83EC 0C	     SUB ESP,0C

;3 Draw speed
;00474F88		  |. E8 7379FBFF    CALL <RISING.GameLoop>  <--- Hook here
;00474F8D		  |. E8 0E28FAFF    CALL <RISING.RequestPaint> <--- Return here

;4 Experimental game logic lock
;0042C944		   . 0F87 3F0C0000	    JA RISING.0042D589 <-- Return to this to abort
;0042C94A		   . 25 FF000000	    AND EAX,0FF
;0042C94F		   . 2E:FF2485 9CC84200     JMP DWORD PTR CS:[EAX*4+42C89C] <--- Hook this





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

  invoke VirtualProtect, [p3a], 5, PAGE_EXECUTE_READWRITE, placeHolder
  mov eax, [p3a]
  mov byte [eax], 0xE9
  mov ecx, patch_3
  sub ecx, eax
  sub ecx, 5
  mov dword [eax+1], ecx

  invoke VirtualProtect, [p4a], 5, PAGE_EXECUTE_READWRITE, placeHolder
  mov eax, [p4a]
  mov byte [eax], 0xE9
  mov ecx, patch_4
  sub ecx, eax
  sub ecx, 5
  mov dword [eax+1], ecx

  or al, 1
  retn

placeHolder dd 0

p1a dd 0043F2E8h
p1r dd 0043F2EDh

p2a dd 48CB32h
p2r dd 48CB37h

p3a dd 00474F88h
p3r dd 00474F8Dh

p4a dd 0042C94Fh
p4r dd 0042D589h

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


patch_3:
CALL [drawProc]
  jmp [p3r]
  invoke GetTickCount
  sub eax, 30
  cmp eax, [drawFrameLock]
  jb @f
    CALL [drawProc]
    invoke GetTickCount
    mov [drawFrameLock], eax
  @@:

  jmp [p3r]
  drawFrameLock dd -1
  drawProc dd 0042C900h

patch_4:
  mov [paramlock], eax
  ;cmp eax, 1
  ;je @f
  ;cmp eax, 6
  ;je @f
  ;cmp eax, 7
  ;je @f
  ;cmp eax, 8
  ;je @f
  ;cmp eax, 9
  ;je @f
  ;cmp eax, 0Ah
  ;je @f
  ;cmp eax, 0Bh
  ;je @f
  ;cmp eax, 0Fh
  ;je @f
  ;cmp eax, 11h  ; <--- Game wont start w/o
  ;je lock_frame
  ;cmp eax, 12h   ; <- Characters wont move
  ;je lock_frame
  cmp eax, 13h
  je @f
  cmp eax, 14h
  je @f
  cmp eax, 15h
  je @f
  cmp eax, 16h
  je @f
  cmp eax, 17h
  je @f
  cmp eax, 18h
  je @f
  proper_jmp:
  mov eax, [paramlock]
  JMP DWORD [EAX*4+42C89Ch]
  @@:
  jmp [p4r]

  lock_frame:
  invoke GetTickCount
  sub eax, 1000 / 10
  cmp eax, [frameStamp]
  jb @b
  invoke GetTickCount
  mov [frameStamp], eax
  jmp proper_jmp

  frameStamp dd 0
  paramlock dd 0


; Special patches

; Windowed

.end start

section 'fxup' fixups readable