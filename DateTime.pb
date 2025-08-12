EnableExplicit

Declare GetInternetTime(List Servers.s(), addhour)
Declare GetTimeZoneOffset()

InitNetwork()


Global idxServers, Timer

Define DateTime
Define Input$
Define PathConfig$
Define Count
Define ini$
Define NotINI = 1
Define notauto = 1
Define addhour = 3
Define NewList Servers.s()

;- ini
PathConfig$ = GetPathPart(ProgramFilename())
If FileSize(PathConfig$ + "DateTime.ini") = -1
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			PathConfig$ = GetHomeDirectory() + "AppData\Roaming\DateTime\"
		CompilerCase #PB_OS_Linux
			PathConfig$ = GetHomeDirectory() + ".config/DateTime/"
			; 		CompilerCase #PB_OS_MacOS
			; 			PathConfig$ = GetHomeDirectory() + "Library/Application Support/DateTime/"
	CompilerEndSelect
EndIf
ini$ = PathConfig$ + "DateTime.ini"


If FileSize(ini$) > 5 And OpenPreferences(ini$)
	NotINI = 0
	PreferenceGroup("set")
	notauto = ReadPreferenceInteger("notauto", notauto)
	addhour = ReadPreferenceInteger("addhour", addhour)

	If PreferenceGroup("servers")
		ExaminePreferenceKeys()
		While NextPreferenceKey()
			If AddElement(Servers())
				Servers() = PreferenceKeyName()
			EndIf
		Wend
	EndIf

	ClosePreferences()
Else
	If AddElement(Servers())
		Servers() = "time.fu-berlin.de"
	EndIf
EndIf


Count = CountProgramParameters()
If Count > 0
	addhour = Val(ProgramParameter(0))
	If Count > 1
; 		вставляем выбранный сервер первым в список
		FirstElement(Servers())
		InsertElement(Servers())
		Servers() = ProgramParameter(1)
		If Count > 2
			notauto = Val(ProgramParameter(2))
		EndIf
	EndIf
EndIf

; нет ini-файла и нет ком-строки, то спрашиваем у пользователя
If notauto
	If NotINI And Not Count
		Input$ = InputRequester("Указать зону", "Например для Москвы это 3", Str(GetTimeZoneOffset()))
		If Asc(Input$)
			addhour = Val(Input$)
		EndIf
	EndIf
Else
	addhour = GetTimeZoneOffset()
EndIf


If addhour > 24
	addhour = GetTimeZoneOffset()
EndIf


DateTime = GetInternetTime(Servers(), addhour)
If Not DateTime
	If notauto
		MessageRequester("Ошибка", "Нет доступа к серверу")
		End 1
	Else
		End 1
	EndIf
EndIf


If notauto = 2
	SelectElement(Servers(), idxServers)
	If MessageRequester("Задать это время в трее?",
						FormatDate("%hh:%ii:%ss %dd.%mm.%yyyy",
						DateTime) + #CRLF$ + "Удачно с " + #DQUOTE$ + Servers() + #DQUOTE$ + " за " + Str(Timer) + " мсек",
						#PB_MessageRequester_YesNo) = #PB_MessageRequester_No
		End 2
	EndIf
EndIf

Define SetTime.SYSTEMTIME
With SetTime
	\wDay = Day(DateTime)
	\wMonth = Month(DateTime)
	\wYear = Year(DateTime)
	\wHour = Hour(DateTime)
	\wMinute = Minute(DateTime)
	\wSecond = Second(DateTime)
EndWith
SetLocalTime_(@SetTime)

End 0




; ts-soft
; https://www.purebasic.fr/english/viewtopic.php?p=352028#p352028
; Изменены входные параметры в отличии от оригинала
Procedure GetInternetTime(List Servers.s(), addhour)
	Protected lSocket
	Protected *lBuffer, lNTPTime
; 	Debug ListSize(Servers()) ; число серверов

	ForEach Servers()
		Timer = ElapsedMilliseconds()
		lSocket = OpenNetworkConnection(Servers(), 37)
; 		выводим сервера при отладке чтобы определить рабочие
; 		Debug Servers()

		If lSocket
			Repeat
				Select NetworkClientEvent(lSocket)
					Case #PB_NetworkEvent_Data
						*lBuffer = AllocateMemory(5)
						If *lBuffer
							If ReceiveNetworkData(lSocket, *lBuffer, 4) = 4
								lNTPTime = (PeekA(*lBuffer + 0)) << 24
								lNTPTime + (PeekA(*lBuffer + 1)) << 16
								lNTPTime + (PeekA(*lBuffer + 2)) << 8
								lNTPTime + (PeekA(*lBuffer + 3))

								lNTPTime = AddDate(lNTPTime - 2840140800, #PB_Date_Year, 20)
								lNTPTime = AddDate(lNTPTime, #PB_Date_Hour, addhour)

								FreeMemory(*lBuffer)
							EndIf
							CloseNetworkConnection(lSocket)
							idxServers = ListIndex(Servers())
							Timer = ElapsedMilliseconds() - Timer
							Break 2
						EndIf
					Case #PB_NetworkEvent_Disconnect
						Break
				EndSelect
			ForEver
		EndIf
	Next

	ProcedureReturn lNTPTime
EndProcedure

Procedure GetTimeZoneOffset()
	Protected nOffSet.f, iTimeZone.Time_Zone_Information
	With iTimeZone
		If GetTimeZoneInformation_(iTimeZone) = #TIME_ZONE_ID_DAYLIGHT
			nOffSet = (\Bias + \DaylightBias)
		Else
			nOffSet = (\Bias + \StandardBias)
		EndIf
	EndWith
	ProcedureReturn Int( - nOffSet / 60)
EndProcedure
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 105
; FirstLine = 85
; Folding = -
; EnableAsm
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = icon.ico
; Executable = DateTime.exe
; CompileSourceDirectory
; DisableCompileCount = 4
; EnableBuildCount = 1
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 0.2.0.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = RegExpPB
; VersionField4 = 0.2.0
; VersionField6 = RegExpPB
; VersionField9 = AZJIO