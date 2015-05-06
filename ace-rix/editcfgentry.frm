VERSION 5.00
Begin VB.Form frmEditCfgEntry 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Edit Configuration Entry"
   ClientHeight    =   754
   ClientLeft      =   1430
   ClientTop       =   1950
   ClientWidth     =   5681
   ControlBox      =   0   'False
   LinkTopic       =   "Form2"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   754
   ScaleWidth      =   5681
   ShowInTaskbar   =   0   'False
   Begin VB.TextBox txtItem1 
      Height          =   247
      Left            =   1521
      TabIndex        =   2
      Top             =   117
      Width           =   1885
   End
   Begin VB.CommandButton cmdOk 
      Caption         =   "Ok"
      Default         =   -1  'True
      Height          =   247
      Left            =   3159
      TabIndex        =   6
      TabStop         =   0   'False
      Top             =   468
      Width           =   1183
   End
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   247
      Left            =   4446
      TabIndex        =   5
      TabStop         =   0   'False
      Top             =   468
      Width           =   1183
   End
   Begin VB.TextBox txtItem2 
      Height          =   247
      Left            =   3744
      TabIndex        =   3
      Top             =   117
      Width           =   1885
   End
   Begin VB.TextBox txtAction 
      Height          =   247
      Left            =   117
      TabIndex        =   0
      Top             =   117
      Width           =   1183
   End
   Begin VB.Label Label2 
      Caption         =   "->"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.83
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   247
      Left            =   3510
      TabIndex        =   4
      Top             =   117
      Width           =   247
   End
   Begin VB.Label Label1 
      Caption         =   ":"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.83
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   247
      Left            =   1404
      TabIndex        =   1
      Top             =   117
      Width           =   130
   End
End
Attribute VB_Name = "frmEditCfgEntry"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Public lstIdx As Integer

Private Sub cmdCancel_Click()
    Me.Hide
End Sub

Private Sub cmdOk_Click()
    Main.lstConf.ListItems(lstIdx).Text = txtAction.Text
    Main.lstConf.ListItems(lstIdx).SubItems(1) = txtItem1.Text
    Main.lstConf.ListItems(lstIdx).SubItems(2) = txtItem2.Text
    
    Me.Hide
End Sub

