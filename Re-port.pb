; -=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-
; Re=port HTML log regenerator v0.4
; Developed in 2014 by Guevara-chan.
; -=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-

EnableExplicit : UseJPEGImageDecoder()
;{ -<Constantionation>-
#InStream     = 0
#OutStream    = 1
#SelXML       = 0
#SelDialog    = 0
#DateTemp     = "%dd.%mm.%yyyy--%hh`%ii`%ss"
#RootPath     = "shots/" 
#SubLog       = "Logae/"
#TitleColor   = "FF8000"
#TitleDelim   = "=►"
#DateDelim    = "==►"
#ShotDelim    = "▲▼"
#ClipDelim    = "【◆►►"
#ClipFinish   = "◄◄◆】"
#ClipCut      = "●●●"
#SelWindow    = 0
#SessionDelim = "〚⇛〛"
;}
;{ -<Enumerations>-
Runtime Enumeration Gadgets
#DonorList
EndEnumeration

Enumeration Indexers
#iDonors
#iChunks
EndEnumeration
;}
;{ -<Definitions>-
Structure GadgetItem : IText.s : *IData : EndStructure
Structure Chunk : Naming.s : TimeStamp.i : EndStructure
Structure Donor : List Chunks.Chunk() : Machinae.s : RawPath.s : LastChange.i : TotalSize.i : ListIdx.i : EndStructure
Define HTMLAccum.s, Springer = #True, RawFile.s
Global NewList Donors.Donor()
;}
;{ -<Math\Logick>-
Macro DefineIIF(TypeID, AltDef) ; Template.
Procedure.TypeID IIF#TypeID(Bool, Val1.TypeID, Val2.TypeID = AltDef)
If Bool : ProcedureReturn Val1 : EndIf : ProcedureReturn Val2
EndProcedure
EndMacro : DefineIIF(s, "") : DefineIIF(i, 0) ; Actual definitions.
;}
;{ -<Input\Output>-
Macro Quotify(Code) ; Pseudo-procedure.
ReplaceString(Code, "'", #DQUOTE$)
EndMacro 

Macro Out(NewCode, NewLiner = #True) ; Pseudo-procedure.
WriteString(#OutStream, NewCode) : Springer = NewLiner
EndMacro

Macro SymmetricalCut(Text, Prefix, Corrector = 0) ; Pseudo-procedure.
Mid(Text, Len(Prefix) + 1, Len(Text) - Len(Prefix) * 2 - Corrector)
EndMacro

Macro ReceiveLine() ; Partializer.
EscapeHTML(ReadString(#InStream))
EndMacro

Procedure Preceded(Sample.s, Pref.s)
ProcedureReturn Bool(CompareMemoryString(@Sample, @Pref, #PB_String_NoCase, Len(Pref)) = #PB_String_Equal)
EndProcedure

Procedure AlbumToDonorIdx(AlbumIdx)
ChangeCurrentElement(Donors(), GetGadgetItemData(#DonorList, AlbumIdx)) : ProcedureReturn ListIndex(Donors())
EndProcedure

Macro SpringCheck() ; Pseudo-procedure.
If Springer = 0 : Out("</br>") : EndIf
EndMacro

Procedure.s EscapeHTML(Code.s)
Define Result.s = Space(Len(Code) * 5), *SChar.Character = @Code, *TChar.Character = @Result
With *SChar                            ; Стандартный посимвольный итератор.
While \C : Select \C                   ; Проходим по всей входной строке с анализом.
Case '<', '>', '&', '"', 39 : Define EBuffer.S{5} = "&#" + \C + ";" ; Escape it now !
CopyMemoryString(@EBuffer, @*TChar)    ; Записываем escape последовательность по ASCII коду.
Default   : *TChar\C = \C : *TChar + SizeOf(Character) ; Просто записываем символ в исходном виде.
EndSelect : *SChar + SizeOf(Character) ; Сдвигаем позицию маркера чтения.
Wend : *TChar\C = #Null                ; На всякий случай дописываем символ конца строки.
EndWith : ProcedureReturn PeekS(@Result)
EndProcedure
;}
;{ -<GUIfication>-
Macro SetupSorting(Pivot) ; Partializer.
SortData\X = OffsetOf(Pivot) : SortData\Y = TypeOf(Pivot)
EndMacro

Procedure.s GetGadgetItemRow(*GadgetID, RowIdx, Columns.i)
Define I, Result.s : Columns - 1 : For I = 0 To Columns : Result = Result + GetGadgetItemText(#DonorList, RowIdx, I) + #LF$ : Next I
ProcedureReturn Result
EndProcedure

Macro GetHeaderText(GadgetID, ColIndex) ; Partializer.
GetGadgetItemText(GadgetID, -1, ColIndex)
EndMacro

Procedure SortListings(ColIdx = 0, ReverseFlag = -1)
Static LastSort : Define Reverse = IIFI(Bool(ReverseFlag = -1), Bool(ColIdx = LastSort - 1), ReverseFlag), SortData.Point
NewList Items.GadgetItem() ; Аккумуляторный список для дальнейшей перестройки LI.
Select ColIdx : Case 0 : SetupSorting(Donor\Machinae)
								Case 1 : SetupSorting(Donor\LastChange)
								Case 2 : SetupSorting(Donor\TotalSize)
EndSelect     : SortStructuredList(Donors(), Reverse, SortData\X, SortData\Y)
ForEach Donors() : AddElement(Items()) : Items()\IText = GetGadgetItemRow(#DonorList, Donors()\ListIdx, 3) 
Items()\IData = GetGadgetItemData(#DonorList, Donors()\ListIdx) : Donors()\ListIdx = ListIndex(Donors()) : Next 
ForEach Items()  : SetGadgetItemText(#DonorList, ListIndex(Items()), Items()\IText) ; Реформируем содержимое ListIcon'а.
SetGadgetItemData(#DonorList, ListIndex(Items()), Items()\IData) : Next
SetGadgetItemText(#DonorList, -1, Mid(GetHeaderText(#DonorList, Abs(LastSort) - 1), 2), Abs(LastSort) - 1)
LastSort = IIFI(Reverse, -ColIDx - 1, ColIDx + 1) ; Выставляем точку последней сортировки.
SetGadgetItemText(#DonorList, -1, IIFS(Reverse, "↓", "↑") + GetHeaderText(#DonorList, ColIdx), ColIdx)
EndProcedure

CompilerSelect #PB_Compiler_OS ; TO.DO: Добавить каких версий вне WinAPI.
CompilerCase #PB_OS_Windows
Macro ChainOldCB(Window = hWnd, Cnt = "OldProc") ; Partialzier.
CallWindowProc_(GetProp_(Window, Cnt), Window, Message, wParam, *lParam)
EndMacro

Macro ChangeCB(GID, CB, Cnt = "OldProc") ; Partializer.
SetProp_(GID, Cnt, SetWindowLongPtr_(GID, #GWL_WNDPROC, @CB))
EndMacro

Procedure SortCallback(*ListID, Message, wParam, *lParam.HD_NOTIFY)
If Message = #WM_NOTIFY And *lParam\hdr\code = #HDN_ITEMCLICK : SortListings(*lParam\iItem) : EndIf    
ProcedureReturn ChainOldCB(*ListID)
EndProcedure
CompilerEndSelect
;}
;{ -<Embedded data>-
DataSection ; Mandatory.
HTMLHeader: : Data.s "<meta charset='utf-8'> <style> " +
"body{ background-color:black; } " +

"@font-face {	font-family: 'Fixedsys';	font-style: normal;	font-weight: normal; " +
"src: local('Fixedsys Excelsior 3.01'), url('" + #PB_Compiler_FilePath + "FSEX300.woff') format('woff'); }" +

"span{ font-family: Sylfaen; color:#00FF00; }" +

"fieldset.title {border-top: 3px double;border-bottom: none;border-left: none;border-right: none;display: " + 
"block; text-align: center; color:red;} " + 

"fieldset.legend { border:3px double red; padding: 5px 10px; font-family: Segoe Print; font-size: 10pt; color:#FF0088; background:#330000}" +

"span.titler {font-family: Verdana; font-size: 10pt; color:" + #TitleColor + "; border: 2px solid ; border-top-style: none;" + 
"border-bottom-style: none; padding: 0 2px;}" +

"hr.titler { border: 1px solid " + #TitleColor + "; }" +

"span.void { color:darkred ; font-family: Segoe UI Black; font-size: 10pt; }" +

"</style>"

SelectorXML: : Data.s "<window id='#SelWindow' name='choices' text='Locate donor for analisys:' minwidth='auto' minheight='auto' " +
"flags='#PB_Window_ScreenCentered | #PB_Window_Tool | #PB_Window_SystemMenu | #PB_Window_Invisible'>" + 
"<vbox><listicon id='#DonorList' width='364' height = '150' flags='#PB_ListIcon_GridLines|#PB_ListIcon_AlwaysShowSelection|" +
"#PB_ListIcon_FullRowSelect'/></vbox>" +
"</window>"
EndDataSection
;}
; =<Initialization>=
Runtime #SelWindow : Define SelBody.s = PeekS(?SelectorXML)                           ; Основные аккумуляторы для диалога.
CatchXML(#SelXML, @SelBody, StringByteLength(SelBody), 0, #PB_UTF8)                   ; Парсим XML из секции данных.
CreateDialog(#SelDialog) : OpenXMLDialog(#SelDialog, #SelXML, "choices")              ; Инициализируем но основе XML-схемы.
; ------
RemoveGadgetColumn(#SelDialog, 0)                                                     ; Оно мне просто надоело, а править корректно - лень.
AddGadgetColumn(#SelDialog, 0, "Machine name [►►] user name:", 180)                   ; Машина-источник списка.
AddGadgetColumn(#SelDialog, 1, "Last update:", 110)                                   ; Дата последнего поступившего куска.
AddGadgetColumn(#SelDialog, 2, "Log size:", 70)                                       ; Полный размер вскех фрагментов лога.
If ExamineDirectory(#iDonors, #RootPath, "*.*")                                       ; Ищем данные изо всех полученных источников. 
While NextDirectoryEntry(#iDonors) : If DirectoryEntryType(#iDonors) = #PB_DirectoryEntry_Directory ; Нас интересуют только директори, отбираем.
Select DirectoryEntryName(#iDonors) : Case ".", ".."                                  ; Сразу отсекаем, ибо зачем нам символические ссылки.
Default : Define DonorPath.s = ReplaceString(GetCurrentDirectory(), "\", "/", #PB_String_InPlace) + #RootPath + DirectoryEntryName(0) +
"/" + #SubLog                                                                         ; Формируем путь к донорским данным.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
If ExamineDirectory(#iChunks, DonorPath, "*.txt") : AddElement(Donors()) : With Donors() ; Пытаемся проанализировать структуру.
\RawPath = DonorPath                                                     ; На будущее, пригодится.
\Machinae = DirectoryEntryName(0) : While NextDirectoryEntry(#iChunks)   ; Сразу запоминаем имя донора.
Define ChunkPath.s = DonorPath + DirectoryEntryName(#iChunks)            ; Формируем полный путь.
If FileSize(ChunkPath) => 0 : AddElement(\Chunks())                      ; Добавляем все фрагменты, которые не директории.
\TotalSize + FileSize(ChunkPath) : \Chunks()\Naming = ChunkPath          ; Формируем размер и загоняем название в список.
\Chunks()\TimeStamp = ParseDate(#DateTemp, GetFilePart(\Chunks()\Naming, #PB_FileSystem_NoExtension)) : EndIf : Wend ; Считываем все даты.
If ListSize(\Chunks())                                                   ; Если в списке фрагментов что-то имеется...                 
SortStructuredList(\Chunks(), #PB_Sort_Ascending, OffsetOf(Chunk\TimeStamp), #PB_Integer) ; Сортируем результатирующий список позиций.
LastElement(\Chunks()) : \LastChange = \Chunks()\TimeStamp               ; Получаем дату последнего поплненимя лога.
AddGadgetItem(#DonorList, -1, \Machinae + #LF$ + FormatDate("%dd.%mm.%yy // [%hh:%ii]", \LastChange) + #LF$ +
StrF(\TotalSize / 1024, 1) + "KB")                                       ; Выхождение в список выбора.
\ListIdx = CountGadgetItems(#DonorList) - 1 : SetGadgetItemData(#DonorList, \ListIdx, @Donors()) ; На будущее.
EndIf : EndIf : EndWith : EndSelect : EndIf : Wend : FinishDirectory(#iDonors) : EndIf     ; Оканчиваем эту часть сканирования.
; --------------------
If CountGadgetItems(#DonorList) = 0 : MessageRequester("=[erroneous activity]=", "No donors was found to analyze") : End : EndIf ; Error message.
SortListings(1, 1) : FirstElement(Donors()) : SetGadgetState(#DonorList, Donors()\ListIdx) ; Сортируем список и выставляем первый элемент.
SetActiveGadget(#DonorList) : HideWindow(#SelWindow, #False)                               ; Последний рубеж перед открытием.
; ------
ChangeCB(GadgetID(#DonorList), SortCallback()) : Repeat : Select WaitWindowEvent()         ; Обработка сообщений, будь она неладна.
Case #PB_Event_Gadget      : Select EventGadget() : Case #DonorList                        ; Если случилось то самое....
If EventType() = #PB_EventType_LeftDoubleClick : AlbumToDonorIdx(GetGadgetState(#DonorList)) : Break : EndIf ; То самое.
EndSelect ; По крайней мере, все это безумие с GUI закончилось. Или почти закончилось...
Case #PB_Event_CloseWindow : End : EndSelect : ForEver  ; Немедленно выходим, как я обожаю обрабатывать это событие.
; =<Non-GUI init>=
If ExamineDirectory(0, #RootPath + Donors()\Machinae, "*.jpg") And NextDirectoryEntry(0) And LoadImage(0, DirectoryEntryName(0)) ; Gервый снимок.
Define PopWidth = ImageWidth(0) / 2, PopHeight = ImageHeight(0) / 2 : FreeImage(0) : FinishDirectory(0)       ; Получаем размеры.
Else : PopWidth = 1280 / 2 : PopHeight = 1024 / 2 : EndIf                                   ; Иначе - ставим стандартные для меня значения.
ExamineDesktops() : Define WinX = (DesktopWidth(0) - PopWidth) / 2, WinY = (DesktopHeight(0) - PopHeight) / 2 ; Координаты грядущих окон.
; ------
Define OutHTML.s = GetTemporaryDirectory() + "Temp.html" ; Формируем путь к выходному HTML-отчету.
CreateFile(#OutStream, OutHTML)                          ; Сразу создаем его до всех операций.      
Out("<head>" + Quotify(ReplaceString(PeekS(?HTMLHeader), "\", "/")) + "</head><body>") ; Подготовка заголовочной информации.
ForEach Donors()\Chunks()
ReadFile(#InStream, Donors()\Chunks()\Naming) 
; =<Main loop>=
While Not Eof(#InStream) : Define LAccum.s = ReceiveLine()                                 ; Считываем по строчке. Классика.
If Preceded(LAccum, #DateDelim)                                                            ; Заголовок сессии. Внушительный разделитель.
SpringCheck() : Out(Quotify("<br><fieldset class='title legend'>") + ReplaceString(Mid(Laccum, Len(#DateDelim) + 1), #SessionDelim,
Quotify("<span style='color:crimson; font-style: italic;'>" + #SessionDelim + "</span>")) + "</fieldset>")
; ------
ElseIf Preceded(LAccum, #TitleDelim)                                                       ; Заголовок нового окна. Разделитель.
Define WinTitle.s = SymmetricalCut(Laccum, #TitleDelim + "[")                              ; Сразу отделяем сам заголовок от плевел.
If WinTitle = "" : WinTitle = "<span class='void'>&lt;No.Name&gt;</span>" : EndIf   ; Заглушка для окон без названия.
Out(Quotify("<table width='100%'><tr><td><hr class='titler'/></td><td style='width:1px; white-space: nowrap;'>" +
"<span class='titler'>") + WinTitle + Quotify("</span></td><td><hr class ='titler'/></td></tr></table>​"))
; ------
ElseIf Preceded(LAccum, #ShotDelim) : Define ShotName.s = Mid(LAccum, 10, Len(LAccum) - 16) ; Ссылка на скриншот. Уплотняем.
Out(Quotify("<a style='text-decoration:none' href='javascript:;' onclick='") + "window.open('file:" + Donors()\RawPath + "../" + ShotName +
"', '_blank','toolbar=0,menubar=0,location=0,width="+PopWidth+",height="+PopHeight+",left="+WinX+",top="+WinY+"')" + #DQUOTE$ + ">" +
"<span style='color:cyan'>" + FormatDate("[%hh:%ii]", ParseDate(#DateTemp+".jpg", ShotName)) + "</span></a>", 0) ; Удобно сокращаем же.
; ------
ElseIf Preceded(LAccum, #ClipDelim)                                                         ; Рапорт о буффере обмена.
While Not Eof(0) And Right(LAccum, Len(#ClipFinish)) <> #ClipFinish : Laccum + ReceiveLine() : Wend ; Ищем окончание фрагмента.
Out(Quotify("<div style='padding:3px; border: dashed 1px ; color:gold; background:#232300; font-family:verdana; margin: 5px; font-size: 7.5pt;" +
"align='justify';'>")+ ReplaceString(SymmetricalCut(Laccum, #ClipDelim) , #ClipCut, "<span style='color:red ; font-family: Palatino Linotype; " +
"font-size: 9pt'> [" + #ClipCut + "]") + "</div>")                      ; Старательно прверащаем в красивый фрагмент.
; ------
ElseIf LAccum : SpringCheck() : Out("<span>" + ReplaceString(ReplaceString(ReplaceString(Laccum, "『?』", ; Стандартный вывод, оформляем.
quotify("<span style='border:1px dashed brown; color:brown ; font-family: Fixedsys'>??</span>")), "『", 
quotify("<span style='border:1px dotted darkgreen; color:darkgreen; font-family: Fixedsys'>")), "』", "</span>") + "</span></br>")
EndIf : Wend : CloseFile(#InStream) : Next : Out("</body>")              ; Финализация.
; =<AfterMath>=
CloseFile(#OutStream) : RunProgram(OutHTML)                              ; Записываем туда сформированный код. 
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; Folding = g8+
; EnableUnicode