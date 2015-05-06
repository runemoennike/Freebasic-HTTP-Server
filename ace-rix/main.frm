VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "comdlg32.ocx"
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.Form Main 
   Caption         =   "ACE-rix - Server interface for x-rix servers"
   ClientHeight    =   6565
   ClientLeft      =   1430
   ClientTop       =   1950
   ClientWidth     =   5980
   LinkTopic       =   "Form1"
   ScaleHeight     =   6565
   ScaleWidth      =   5980
   Begin VB.Timer tmrCheckRunning 
      Left            =   0
      Top             =   0
   End
   Begin VB.Frame frmRunCtrl 
      Caption         =   "Run control"
      Height          =   1534
      Left            =   117
      TabIndex        =   10
      Top             =   117
      Width           =   5746
      Begin VB.CommandButton cmdAddServer 
         Caption         =   "Add Server"
         Enabled         =   0   'False
         Height          =   364
         Left            =   4446
         TabIndex        =   5
         Top             =   1053
         Width           =   1183
      End
      Begin VB.CommandButton cmdConfPath 
         Caption         =   "Change Path"
         Height          =   364
         Left            =   3159
         TabIndex        =   4
         Top             =   1053
         Width           =   1183
      End
      Begin VB.CommandButton cmdStop 
         Caption         =   "Stop"
         Height          =   364
         Left            =   1404
         TabIndex        =   3
         Top             =   1053
         Width           =   1183
      End
      Begin VB.CommandButton cmdStartStop 
         Caption         =   "Start"
         Height          =   364
         Left            =   117
         TabIndex        =   2
         Top             =   1053
         Width           =   1183
      End
      Begin VB.ListBox lstServers 
         Height          =   728
         Left            =   117
         TabIndex        =   1
         Top             =   234
         Width           =   5512
      End
   End
   Begin VB.Frame frmConf 
      Caption         =   "Configuration"
      Height          =   4693
      Left            =   117
      TabIndex        =   0
      Top             =   1755
      Width           =   5746
      Begin VB.CommandButton cmdEditCfgEntry 
         Caption         =   "Edit Entry"
         Default         =   -1  'True
         Height          =   364
         Left            =   234
         TabIndex        =   7
         Top             =   4212
         Width           =   1300
      End
      Begin VB.CommandButton cmdAddCfgEntry 
         Caption         =   "Add New Entry"
         Height          =   364
         Left            =   4095
         TabIndex        =   9
         Top             =   4212
         Width           =   1300
      End
      Begin VB.CommandButton cmdRemoveCfgEntry 
         Caption         =   "Remove Entry"
         Height          =   364
         Left            =   1638
         TabIndex        =   8
         Top             =   4212
         Width           =   1417
      End
      Begin MSComctlLib.ListView lstConf 
         Height          =   3991
         Left            =   117
         TabIndex        =   6
         Top             =   234
         Width           =   5629
         _ExtentX        =   9920
         _ExtentY        =   7045
         View            =   3
         LabelEdit       =   1
         LabelWrap       =   -1  'True
         HideSelection   =   -1  'True
         FullRowSelect   =   -1  'True
         _Version        =   393217
         ForeColor       =   -2147483640
         BackColor       =   -2147483643
         BorderStyle     =   1
         Appearance      =   1
         NumItems        =   4
         BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
            Text            =   "Action"
            Object.Width           =   1588
         EndProperty
         BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
            SubItemIndex    =   1
            Text            =   "Value/Object Item"
            Object.Width           =   3440
         EndProperty
         BeginProperty ColumnHeader(3) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
            SubItemIndex    =   2
            Text            =   "Second Item"
            Object.Width           =   3440
         EndProperty
         BeginProperty ColumnHeader(4) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
            Alignment       =   2
            SubItemIndex    =   3
            Text            =   "L#"
            Object.Width           =   619
         EndProperty
      End
   End
   Begin MSComDlg.CommonDialog comdia 
      Left            =   1404
      Top             =   3510
      _ExtentX        =   767
      _ExtentY        =   767
      _Version        =   393216
   End
End
Attribute VB_Name = "Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim httPath As String, ftpPath As String

Const updateRunStatTime = 1000

Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (ByVal hWnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long


'Windows 95/98 platform
Private Declare Function CreateToolhelp32Snapshot Lib "kernel32" (ByVal dwFlags As Long, ByVal th32ProcessID As Long) As Long
Private Declare Function Process32First Lib "kernel32" (ByVal hSnap As Long, lppe As PROCESSENTRY32) As Long
Private Declare Function Process32Next Lib "kernel32" (ByVal hSnap As Long, lppe As PROCESSENTRY32) As Long

'Windows NT platform
Private Declare Function EnumProcesses Lib "psapi" (lpIdProcess As Any, ByVal cb As Long, cbNeeded As Long) As Long
Private Declare Sub CloseHandle Lib "kernel32" (ByVal hPass As Long)
Private Declare Function OpenProcess Lib "kernel32" (ByVal dwDesiredAccess As Long, ByVal bInheritHandle As Long, ByVal dwProcessId As Long) As Long
Private Declare Function GetModuleBaseName Lib "PSAPI.DLL" Alias "GetModuleBaseNameA" (ByVal hProcess As Long, ByVal hModule As Long, ByVal lpFileName As String, ByVal nSize As Long) As Long
Private Declare Function EnumProcessModules Lib "PSAPI.DLL" (ByVal hProcess As Long, lphModule As Long, ByVal cb As Long, lpcbNeeded As Long) As Long

Private Declare Function TerminateProcess Lib "kernel32" (ByVal hProcess As Long, ByVal uExitCode As Long) As Long
Private Const PROCESS_TERMINATE As Long = &H1


Private Const MAX_PATH As Integer = 260

Private Type PROCESSENTRY32
  lSize As Long
  cntUsage As Long
  th32ProcessID As Long
  th32DefaultHeapID As Long
  th32ModuleID As Long
  cntThreads As Long
  th32ParentProcessID As Long
  pcPriClassBase As Long
  dwFlags As Long
  sExeFile As String * MAX_PATH
End Type

'Purpose : Enumerate the current processes and return names and process IDs.
'Inputs : [sFilter] If set will only return processes containing this string.
' [bWINNT] Set this to True when running on NT machines.
'Outputs : Returns the number of processes, or -1 if an error occurs.
' asProcessNames A 1d string array containing the system processes.
' alProcIDs A 1d long array of Process IDs corresponding to the names given in the
' string array

Function EnumProcs(asProcessNames() As String, alProcIDs() As Long, Optional sFilter As String, Optional bWINNT As Boolean)
  Dim lhwnSnapShot As Long, tProcess As PROCESSENTRY32, lThisProc As Long, sThisProc As String
  Dim bFiltered As Boolean, alAllProcIDs() As Long
  Dim lCB As Long
  
  Const TH32CS_SNAPHEAPLIST = &H1, TH32CS_SNAPPROCESS = &H2, TH32CS_SNAPTHREAD = &H4
  Const TH32CS_SNAPMODULE = &H8
  Const TH32CS_SNAPALL = (TH32CS_SNAPHEAPLIST Or TH32CS_SNAPPROCESS Or TH32CS_SNAPTHREAD Or TH32CS_SNAPMODULE)
  Const TH32CS_INHERIT = &H80000000
  
  On Error GoTo ErrFailed
  Erase asProcessNames
  Erase alProcIDs
  
  bFiltered = Len(sFilter)
  
  If bWINNT Then
'-------Windows NT platform
    lCB = 512
    Do
      ReDim alAllProcIDs(0 To (lCB \ 4) - 1) As Long
      If EnumProcesses(alAllProcIDs(0), lCB, lThisProc) = 0 Then
        'Failed
        EnumProcs = -1
        Exit Function
      End If
      If lThisProc <= lCB Then
        'Retrieved all the process IDs
        Exit Do
      End If
      'Increase the size of the array to hold the ProcIDs
      lCB = lCB * 2
    Loop
    
    lCB = (lThisProc \ 4) - 1
    
    'Resize arrays
    ReDim Preserve alAllProcIDs(0 To lCB) As Long
    ReDim asProcessNames(1 To lCB + 1)
    ReDim alProcIDs(1 To lCB + 1)

    'Get the process names
    For lThisProc = 0 To lCB
      sThisProc = GetProcessName(alAllProcIDs(lThisProc))
      If Len(sThisProc) Then
        If bFiltered Then
          'Filter the list of processes returned
          If InStr(1, sThisProc, sFilter, vbBinaryCompare) Then
            EnumProcs = EnumProcs + 1
            asProcessNames(EnumProcs) = sThisProc
            MsgBox asProcessNames(EnumProcs)
            alProcIDs(EnumProcs) = alAllProcIDs(lThisProc)
          End If
        Else
          EnumProcs = EnumProcs + 1
          asProcessNames(EnumProcs) = sThisProc
          alProcIDs(EnumProcs) = alAllProcIDs(lThisProc)
        End If
      End If
    Next
    If EnumProcs And EnumProcs <> lCB + 1 Then
      ReDim Preserve asProcessNames(1 To EnumProcs)
      ReDim Preserve alProcIDs(1 To EnumProcs)
    Else
      Erase asProcessNames
    End If
  Else
'-------Windows 95/98 platform
    
    'Get a handle to a snapshot of the processes (and modules, threads, heaps used by the processes)
    lhwnSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0&)
    tProcess.lSize = Len(tProcess)
    ReDim asProcessNames(1 To 1)
    ReDim alProcIDs(1 To 1)
    
    
    'Get first process in snapshot
    lThisProc = Process32First(lhwnSnapShot, tProcess)
    
    Do While lThisProc
      
      sThisProc = Left$(tProcess.sExeFile, IIf(InStr(1, tProcess.sExeFile, Chr$(0)) > 0, InStr(1, tProcess.sExeFile, Chr$(0)) - 1, 0))
      If Len(sThisProc) Then
        If bFiltered Then
          'Filter the list of processes returned
          If InStr(1, sThisProc, sFilter, vbBinaryCompare) Then
            EnumProcs = EnumProcs + 1
            ReDim Preserve asProcessNames(1 To EnumProcs)
            ReDim Preserve alProcIDs(1 To EnumProcs)
            asProcessNames(EnumProcs) = sThisProc
            alProcIDs(EnumProcs) = tProcess.th32ProcessID
          End If
        Else
          EnumProcs = EnumProcs + 1
          ReDim Preserve asProcessNames(1 To EnumProcs)
          ReDim Preserve alProcIDs(1 To EnumProcs)
          asProcessNames(EnumProcs) = sThisProc
          If InStr(sThisProc, "iexplore.exe") Then
            Target = tProcess.th32ProcessID
            'Call AskForKill
        End If
          alProcIDs(EnumProcs) = tProcess.th32ProcessID
        End If
      End If
      'Get next process in snapshot
      lThisProc = Process32Next(lhwnSnapShot, tProcess)
    Loop
    'close snapshot
    CloseHandle lhwnSnapShot
  End If
  
  Exit Function

ErrFailed:
  Erase asProcessNames
  Erase alProcIDs
  EnumProcs = -1
  On Error GoTo 0
End Function

Public Function GetProcessName(ByVal lProcessID As Long) As String
Dim szProcessName As String
Dim lLen As Long, hProcess As Long
Dim alhwndMod(0 To 1023) As Long
Dim lcbNeeded As Long
Dim lCounter As Long
Dim lR As Long
Const PROCESS_QUERY_INFORMATION = &H400
Const PROCESS_VM_READ = &H10
lLen = MAX_PATH
hProcess = OpenProcess(PROCESS_QUERY_INFORMATION Or PROCESS_VM_READ, 0, lProcessID)
If (lProcessID = 0) Then
GetProcessName = "System Idle Process"
ElseIf (lProcessID = 2) Then
GetProcessName = "System"
Else
'Get the process name
If (hProcess <> 0) Then
If (EnumProcessModules(hProcess, alhwndMod(0), 1024 * 4, lcbNeeded)) Then
szProcessName = String$(lLen, 0)
LSet szProcessName = "unknown"
lR = GetModuleBaseName(hProcess, alhwndMod(lCounter), szProcessName, lLen)
GetProcessName = Left$(szProcessName, InStr(szProcessName, vbNullChar) - 1)
End If
End If
End If
CloseHandle hProcess
End Function
'Demonstration routine
Sub Test()
Dim lThisProc As Long, lNumProcs As Long, asProcNames() As String, alProcIDs() As Long
'WIN NT Test
lNumProcs = EnumProcs(asProcNames, alProcIDs, , True)
For lThisProc = 1 To lNumProcs
Debug.Print asProcNames(lThisProc) & vbTab & "ID:" & alProcIDs(lThisProc)
Next
'95/98/2000 Test
lNumProcs = EnumProcs(asProcNames, alProcIDs)
For lThisProc = 1 To lNumProcs
Debug.Print asProcNames(lThisProc) & vbTab & "ID:" & alProcIDs(lThisProc)
Next
End Sub

Private Sub cmbConfFiles_Click()

End Sub

Private Sub cmdEditCfgEntry_Click()
With frmEditCfgEntry
    .txtAction.Text = lstConf.SelectedItem.Text
    .txtItem1.Text = lstConf.SelectedItem.SubItems(1)
    .txtItem2.Text = lstConf.SelectedItem.SubItems(2)
    .lstIdx = lstConf.SelectedItem.Index

    .Top = Me.Top + lstConf.Top + lstConf.Height
    .Left = Me.Left + 400
    .Show 1, Me
End With
End Sub

Private Sub cmdStartStop_Click()
    spl1 = InStr(lstServers.List(lstServers.ListIndex), "(")
    spl2 = InStr(spl1, lstServers.List(lstServers.ListIndex), ")")
    exePath = Mid(lstServers.List(lstServers.ListIndex), spl1 + 1, spl2 - spl1 - 1)
    exefile = exePath & Trim(Left(lstServers.List(lstServers.ListIndex), spl1 - 1)) & ".exe"
    
    ShellExecute Me.hWnd, vbNullString, exefile, vbNullString, exePath, 0
End Sub

Private Sub cmdStop_Click()
    
    spl1 = InStr(lstServers.List(lstServers.ListIndex), "(")
    spl2 = InStr(spl1, lstServers.List(lstServers.ListIndex), ")")
    spl3 = InStr(spl2, lstServers.List(lstServers.ListIndex), ":")
    firstPart = Left(lstServers.List(lstServers.ListIndex), spl3 - 1)
    exePath = Mid(lstServers.List(lstServers.ListIndex), spl1 + 1, spl2 - spl1 - 1)
    
    fh = FreeFile
    Open exePath & "msg.dat" For Output As #fh
        Print #fh, Left$(Date$, 2) & Mid$(Date$, 4, 2) & Left$(Time$, 2) & Mid$(Time$, 4, 2) & Right$(Time$, 2) & ": ACE shd"
    Close #fh
    
    lstServers.List(lstServers.ListIndex) = firstPart & ": Pending..."
End Sub

Private Sub Form_Load()
httPath = GetSetting("x-rix", "paths", "htt_conf", "")
ftpPath = GetSetting("x-rix", "paths", "ftp_conf", "")

If httPath = "" Then
    MsgBox "ACE-rix could not detect where HTT-rix is installed. Press OK to locate the HTT-rix configuration file (htt-rix.conf)."
    inpPath "htt"
End If

If ftpPath = "" Then
    MsgBox "ACE-rix could not detect where FTP-rix is installed. Press OK to locate the FTP-rix configuration file (ftp-rix.conf)."
    inpPath "ftp"
End If

lstServers.AddItem "HTT-rix (" & httPath & "): Status Pending..."
lstServers.AddItem "FTP-rix (" & ftpPath & "): Status Pending..."

tmrCheckRunning.Interval = updateRunStatTime
tmrCheckRunning.Enabled = True

End Sub

Sub inpPath(forwhat As String)
    If forwhat = "htt" Then
        comdia.DefaultExt = ".conf"
        comdia.DialogTitle = "Please locate HTT-rix.conf"
        comdia.FileName = "HTT-rix.conf"
        comdia.Filter = "x-rix Configuration Files (*.conf)|*.conf|All Files (*.*)|*.*"
        comdia.Flags = cdlOFNHideReadOnly Or cdlOFNPathMustExist
        comdia.ShowOpen
        
        httPath = getPath(comdia.FileName)
    ElseIf forwhat = "ftp" Then
        comdia.DefaultExt = ".conf"
        comdia.DialogTitle = "Please locate FTP-rix.conf"
        comdia.FileName = "FTP-rix.conf"
        comdia.Filter = "x-rix Configuration Files (*.conf)|*.conf|All Files (*.*)|*.*"
        comdia.Flags = cdlOFNHideReadOnly Or cdlOFNPathMustExist
        comdia.ShowOpen
        
        ftpPath = getPath(comdia.FileName)
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    SaveSetting "x-rix", "paths", "htt_conf", httPath
    SaveSetting "x-rix", "paths", "ftp_conf", ftpPath
End Sub

Function getPath(ByVal spec As String) As String
    For p = Len(spec) To 1 Step -1
        getPath = Left$(spec, p)
        
        If Mid(spec, p, 1) = "\" Then Exit Function
    Next p
End Function

Private Sub lstConf_DblClick()
cmdEditCfgEntry_Click
End Sub

Private Sub lstServers_Click()
lstConf.ListItems.Clear

spl1 = InStr(lstServers.List(lstServers.ListIndex), "(")
spl2 = InStr(spl1, lstServers.List(lstServers.ListIndex), ")")
cfgFile = Mid(lstServers.List(lstServers.ListIndex), spl1 + 1, spl2 - spl1 - 1) & Trim(Left(lstServers.List(lstServers.ListIndex), spl1 - 1)) & ".conf"

fh = FreeFile
On Error GoTo notFound
Open cfgFile For Input As #fh
On Error GoTo 0
    lineNum = 1
    Do
        Line Input #fh, tmp$
        If InStr(tmp$, "#") Then tmp$ = Left$(tmp$, InStr(tmp$, "#") - 1)
        tmp$ = Trim(tmp$)
            
        spl = InStr(tmp$, ":")
        If spl > 1 Then
            Action$ = Trim(Left$(tmp$, spl - 1))
            args$ = Trim(Mid$(tmp$, spl + 1))
            
            Set itmx = lstConf.ListItems.Add(, , Action$)
            
            spl = InStr(args$, "->")
            If spl > 0 Then
                obj$ = Left$(args$, spl - 1)
                valu$ = Mid$(args$, spl + 2)
                itmx.SubItems(1) = obj$
                itmx.SubItems(2) = valu$
            Else
                itmx.SubItems(1) = args$
            End If
            
            itmx.SubItems(3) = lineNum
        ElseIf Left(tmp$, 1) = "[" Then
            Set itmx = lstConf.ListItems.Add(, , " ")
            
            Set itmx = lstConf.ListItems.Add(, , tmp$)
            
        End If
        lineNum = lineNum + 1
    Loop Until EOF(fh)
Close

Exit Sub

notFound:
    MsgBox "The file '" & cfgFile & "' does not exist. Please locate the correct configuration file."
    
    If InStr(1, cfgFile, "ftp-rix.conf", vbTextCompare) Then
        inpPath "ftp"
    ElseIf InStr(1, cfgFile, "htt-rix.conf", vbTextCompare) Then
        inpPath "htt"
    End If
    
Resume
End Sub

Private Sub tmrCheckRunning_Timer()
Dim pnames() As String, pids() As Long
EnumProcs pnames(), pids()


For i = 0 To lstServers.ListCount
    If Len(lstServers.List(i)) > 0 Then
        spl1 = InStr(lstServers.List(i), "(")
        spl2 = InStr(spl1, lstServers.List(i), ")")
        spl3 = InStr(spl2, lstServers.List(i), ":")
        exefile = Trim(Left(lstServers.List(i), spl1 - 1)) & ".exe"
        firstPart = Left(lstServers.List(i), spl3 - 1)
        curStat = Mid(lstServers.List(i), spl3 + 1)

        'deb = ""
        statust = "Not running"
        For p = LBound(pnames) To UBound(pnames)
            If Trim(LCase(pnames(p))) = Trim(LCase(exefile)) Then
                statust = "Running"
                If InStr(LCase(curStat), "pending") Then statust = "Pending..."
            End If
            'deb = deb & pnames(p) & vbNewLine
        Next p
        
        
        'MsgBox deb
        
        lstServers.List(i) = firstPart & ": " & statust
    End If
Next i
End Sub
