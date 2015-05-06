'/***********************************************************
'* MD5 FreeBasic Implementation                             *
'* By Neo                                                   *
'* 21st March 2005, somewhere near noon                     *
'*                                                          *
'* Specially made for J. "Z!re" Pihl                        *
'*                                                          *
'* Personal Comment:                                        *
'* After 2 hours of coding finally a working version ^_^    *
'* MD5_crc is the main calling function, that returns a Ptr *
'* to an 4-sized array of UINTs (128 bit). Be sure to       *
'* deallocate the result after used.                        *
'* NOTE: Delete the "some test stuff" section between # if  *
'*       you understand how it works and want to use it.    *
'***********************************************************/

#define UINT unsigned integer

'For J. "Z!re" Pihl's extraordinary random series generator ^_^
'$Include: 'src_inc/_xirt.bi'

Declare Function MD5_crc (MemPtr As UByte Ptr, MemLen As UINT) As UINT Ptr
Declare Sub MD5_Internal_ShutDown (inputbuffer As UByte Ptr, CountPtr As UINT Ptr, StatePtr As UINT Ptr, ResMD As UByte Ptr)
Declare Sub MD5_Internal_UpdateComponent (UData As UByte Ptr, StatePtr As UINT Ptr)
Declare Sub MD5_Internal_AddChecksum (DataPtr As UByte Ptr, DataLen As UINT, Comp As UINT Ptr, Bits As UINT Ptr, Calc As UByte Ptr)
Declare Sub MD5_Internal_MemCopy (ToPtr As UByte Ptr, FromPtr As UByte Ptr, Length As UINT)
Declare Sub MD5_Internal_UI2UB (OutputPtr As UByte Ptr, InputPtr As UINT Ptr, Length As UINT)
Declare Sub MD5_Internal_UB2UI (OutputPtr As UINT Ptr, InputPtr As UByte Ptr, Length As UINT)
Declare Function MD5_Internal_ExecutePrimitiveFunction (x As UINT, y As UINT, z As UINT, OperationNumber As Short) As UINT
Declare Sub MD5_Internal_ExecuteFunction (a As UINT Ptr, b As UINT Ptr, c As UINT Ptr, d As UINT Ptr, BLX As UINT Ptr, ProcKey As UINT, UKey As UINT, OperationNumber As UByte)
Declare Function MD5_Internal_BitRotate (v As UINT, n As UINT) As UINT



'input "MD5: ", abbb$ 
'
'Dim Result As UINT Ptr 
'Result = MD5_crc(strptr(abbb$), len(abbb$)) 
'For i = 0 To 3 
'   Print String$(8 - Len(Hex$(Result[i])), "0") + (Hex$(Result[i])); 
'Next i 
' 
'Do While Inkey$ = "" 
'Loop 
' 
'deallocate Result 
'System




'some test stuff
'#############################################################################
'Open "Video1.avi" For Binary As #1
'   flen = LoF(1)
'   Dim BBB(flen - 1) As UByte
'   Get #1, , BBB()
'Close #1

'Dim Result As UINT Ptr
'Result = MD5_crc(@BBB(0), flen)
'Print "&H";
'For i = 0 To 3
'   Print String$(8 - Len(Hex$(Result[i])), "0") + UCase$(Hex$(Result[i]));
'Next i

'Do While Inkey$ = ""
'Loop

'Adeallocate Result
'System
'############################################################################





Private Function MD5_crc (MemPtr As UByte Ptr, MemLen As UINT) As UINT Ptr
   'Create result storage
   Dim ResultMDM As UINT Ptr
   ResultMDM = callocate(4 * Len(UINT))
   ResultMDM[0] = 0
   ResultMDM[1] = 0
   ResultMDM[2] = 0
   ResultMDM[3] = 0
   
   'Basic startup components
   Dim Component(3) As UINT
   Component(0) = &H67452301
   Component(1) = &HEFCDAB89
   Component(2) = &H98BADCFE
   Component(3) = &H10325476
   
   Dim BitNumber(1) As UINT
   BitNumber(0) = 0
   BitNumber(1) = 0
   
   'Some memread-necessities
   Dim buffer(512) As UByte, readmem As UINT, bufferlen As UINT
   Dim CalcBuffer(64) As UByte
   
   'Print buffer
   readmem = 0
   Do While readmem < MemLen
      If readmem + 512 > MemLen Then bufferlen = MemLen - readmem Else bufferlen = 512
      
      'Copy from memory to buffer
      MD5_Internal_MemCopy @buffer(0), MemPtr + readmem, bufferlen
      'Add the buffer to the checksum
      MD5_Internal_AddChecksum @buffer(0), bufferlen, @Component(0), @BitNumber(0), @CalcBuffer(0)
      
      readmem = readmem + bufferlen
   Loop
   
   'Apply a trick for when MemLen < 65 using a random password generator made by J. "Z!re" Pihl
   'Thanks to J. "Z!re" Pihl for very nicely pointing this out
   If MemLen < 65 Then
      Dim ReCallSeed As UINT, i As UINT, PLen As UINT, PData As UByte Ptr
      ReCallSeed = 3: i = 0
      Do While i < MemLen
         ReCallSeed = (((ReCallSeed Xor Not(MemPtr[i])) + MemPtr[i]) And &HFF)
         i = i + 1
      Loop
      Do
         PData = getPwd(ReCallSeed)
         PLen = (PData[0] shl 8) Or PData[1]
         If PLen < 65 Then
               ReCallSeed = ReCallSeed + 1
               deallocate PData
         End If
      Loop Until PLen >= 65
      MD5_Internal_AddChecksum PData + 2, PLen, @Component(0), @BitNumber(0), @CalcBuffer(0)
      deallocate Pdata
   End If   
         
   'Shut down the process
   Dim ResultMD(15) As UByte
   MD5_Internal_ShutDown @CalcBuffer(0), @BitNumber(0), @Component(0), @ResultMD(0)
   
   'Give correct format and return
   MD5_Internal_UB2UI ResultMDM, @ResultMD(0), 16
   MD5_crc = ResultMDM
End Function

Private Sub MD5_Internal_ShutDown (inputbuffer As UByte Ptr, CountPtr As UINT Ptr, StatePtr As UINT Ptr, ResMD As UByte Ptr)
   'Retrieve number of bits
   Dim NoBits(7) As UByte
   MD5_Internal_UI2UB @NoBits(0), CountPtr, 8
   
   'Get amount of padding
   Dim BitMod As UINT, padlength As UINT
   BitMod = (CountPtr[0] shr 3) And &H3F
   If BitMod < 56 Then padlength = 56 - BitMod Else padlength = 120 - BitMod
   
   'Set padding
   Dim Pad(63) As UByte, l As Short
   For l = 0 To 63
      Pad(l) = 0
   Next l   
   Pad(0) = &H80
   MD5_Internal_AddChecksum @Pad(0), padlength, CountPtr, StatePtr, inputbuffer
   MD5_Internal_AddChecksum @NoBits(0), 8, CountPtr, StatePtr, inputbuffer
   
   MD5_Internal_UI2UB ResMD, StatePtr, 16
   
   For l = 0 To 63
         inputbuffer[l] = 0
   Next l   
End Sub

Private Sub MD5_Internal_UpdateComponent (UData As UByte Ptr, StatePtr As UINT Ptr)
   'Create temporary variables
   Dim StateTMP(3) As UINT, BlockData(15) As UINT
   StateTMP(0) = StatePtr[0]
   StateTMP(1) = StatePtr[1]
   StateTMP(2) = StatePtr[2]
   StateTMP(3) = StatePtr[3]
   
   MD5_Internal_UB2UI @BlockData(0), UData, 64
   
   'Now create some constant variables
   Dim Proc1Sub1 As UINT, Proc1Sub2 As UINT, Proc1Sub3 As UINT, Proc1Sub4 As UINT
   Dim Proc2Sub1 As UINT, Proc2Sub2 As UINT, Proc2Sub3 As UINT, Proc2Sub4 As UINT
   Dim Proc3Sub1 As UINT, Proc3Sub2 As UINT, Proc3Sub3 As UINT, Proc3Sub4 As UINT
   Dim Proc4Sub1 As UINT, Proc4Sub2 As UINT, Proc4Sub3 As UINT, Proc4Sub4 As UINT
   Proc1Sub1 = 5: Proc1Sub2 = 12: Proc1Sub3 = 17: Proc1Sub4 = 22
   Proc2Sub1 = 5: Proc2Sub2 = 9: Proc2Sub3 = 14: Proc2Sub4 = 20
   Proc3Sub1 = 4: Proc3Sub2 = 11: Proc3Sub3 = 16: Proc3Sub4 = 23
   Proc4Sub1 = 6: Proc4Sub2 = 10: Proc4Sub3 = 15: Proc4Sub4 = 21
   
   ' First section 1-16
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(0), Proc1Sub1, &HD76AA478, 1
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(1), Proc1Sub2, &HE8C7B756, 1
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(2), Proc1Sub3, &H242070DB, 1
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(3), Proc1Sub4, &HC1BDCEEE, 1
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(4), Proc1Sub1, &HF57C0FAF, 1
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(5), Proc1Sub2, &H4787C62A, 1
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(6), Proc1Sub3, &HA8304613, 1
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(7), Proc1Sub4, &HFD469501, 1
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(8), Proc1Sub1, &H698098D8, 1
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(9), Proc1Sub2, &H8B44F7AF, 1
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(10), Proc1Sub3, &HFFFF5BB1, 1
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(11), Proc1Sub4, &H895CD7BE, 1
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(12), Proc1Sub1, &H6B901122, 1
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(13), Proc1Sub2, &HFD987193, 1
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(14), Proc1Sub3, &HA679438E, 1
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(15), Proc1Sub4, &H49B40821, 1
   
   ' Second section 17-32
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(1), Proc2Sub1, &HF61E2562, 2
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(6), Proc2Sub2, &HC040B340, 2
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(11), Proc2Sub3, &H265E5A51, 2
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(0), Proc2Sub4, &HE9B6C7AA, 2
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(5), Proc2Sub1, &HD62F105D, 2
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(10), Proc2Sub2, &H02441453, 2
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(15), Proc2Sub3, &HD8A1E681, 2
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(4), Proc2Sub4, &HE7D3FBC8, 2
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(9), Proc2Sub1, &H21E1CDE6, 2
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(14), Proc2Sub2, &HC33707D6, 2
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(3), Proc2Sub3, &HF4D50D87, 2
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(8), Proc2Sub4, &H455A14ED, 2
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(13), Proc2Sub1, &HA9E3E905, 2
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(2), Proc2Sub2, &HFCEFA3F8, 2
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(7), Proc2Sub3, &H676F02D9, 2
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(12), Proc2Sub4, &H8D2A4C8A, 2
   
   ' Third section 33-48
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(5), Proc3Sub1, &HFFFA3942, 3
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(8), Proc3Sub2, &H8771F681, 3
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(11), Proc3Sub3, &H6D9D6122, 3
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(14), Proc3Sub4, &HFDE5380C, 3
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(1), Proc3Sub1, &HA4BEEA44, 3
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(4), Proc3Sub2, &H4BDECFA9, 3
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(7), Proc3Sub3, &HF6BB4B60, 3
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(10), Proc3Sub4, &HBEBFBC70, 3
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(13), Proc3Sub1, &H289B7EC6, 3
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(0), Proc3Sub2, &HEAA127FA, 3
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(3), Proc3Sub3, &HD4EF3085, 3
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(6), Proc3Sub4, &H04881D05, 3
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(9), Proc3Sub1, &HD9D4D039, 3
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(12), Proc3Sub2, &HE6DB99E5, 3
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(15), Proc3Sub3, &H1FA27CF8, 3
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(2), Proc3Sub4, &HC4AC5665, 3
   
   ' Fourth section 49-64
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(5), Proc4Sub1, &HF4292244, 4
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(8), Proc4Sub2, &H432AFF97, 4
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(11), Proc4Sub3, &HAB9423A7, 4
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(14), Proc4Sub4, &HFC93A039, 4
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(1), Proc4Sub1, &H655B59C3, 4
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(4), Proc4Sub2, &H8F0CCC92, 4
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(7), Proc4Sub3, &HFFEFF47D, 4
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(10), Proc4Sub4, &H85845DD1, 4
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(13), Proc4Sub1, &H6FA87E4F, 4
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(0), Proc4Sub2, &HFE2CE6E0, 4
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(3), Proc4Sub3, &HA3014341, 4
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(6), Proc4Sub4, &H4E0811A1, 4
   MD5_Internal_ExecuteFunction @StateTMP(0), @StateTMP(1), @StateTMP(2), @StateTMP(3), @BlockData(9), Proc4Sub1, &HF7537E82, 4
   MD5_Internal_ExecuteFunction @StateTMP(3), @StateTMP(0), @StateTMP(1), @StateTMP(2), @BlockData(12), Proc4Sub2, &HBD3AF235, 4
   MD5_Internal_ExecuteFunction @StateTMP(2), @StateTMP(3), @StateTMP(0), @StateTMP(1), @BlockData(15), Proc4Sub3, &H2AD7D2BB, 4
   MD5_Internal_ExecuteFunction @StateTMP(1), @StateTMP(2), @StateTMP(3), @StateTMP(0), @BlockData(2), Proc4Sub4, &HEB86D391, 4

   StatePtr[0] = StateTMP(0)
   StatePtr[1] = StateTMP(1)
   StatePtr[2] = StateTMP(2)
   StatePtr[3] = StateTMP(3)
   
   Dim k As Short
   For k = 0 To 15
      BlockData(k) = 0
   Next k   
End Sub

Private Sub MD5_Internal_AddChecksum (DataPtr As UByte Ptr, DataLen As UINT, Comp As UINT Ptr, Bits As UINT Ptr, Calc As UByte Ptr)

   'Calculate amount of remaining bytes in buffer
   Dim buffer_position As UINT, buffer_left As UINT
   buffer_position = (Bits[0] shr 3) And 63
   buffer_left = 64 - buffer_position
   
   'Update amount of bits read
   Dim OldBit As UINT, input_position As UINT
   OldBit = Bits[0]
   Bits[0] = Bits[0] + (DataLen shl 3)
   If OldBit > Bits[0] Then Bits[1] = Bits[1] + 1
   Bits[1] = Bits[1] + (DataLen shr 29)
   
   'Can we fill the whole buffer at once?
   If DataLen > buffer_left Then
      'Yes, do it
      MD5_Internal_MemCopy Calc + buffer_position, DataPtr, buffer_left
      MD5_Internal_UpdateComponent Calc, Comp
      
      'Process any remaining blocks
      input_position = buffer_left
      Do While input_position + 63 < DataLen
         MD5_Internal_UpdateComponent DataPtr + input_position, Comp
         input_position = input_position + 64
      Loop      
      buffer_position = 0
   Else
      'No, then add to buffer
      input_position = 0
   End If  
   
   MD5_Internal_MemCopy Calc + buffer_position, DataPtr + input_position, DataLen - input_position
End Sub

Private Sub MD5_Internal_MemCopy (ToPtr As UByte Ptr, FromPtr As UByte Ptr, Length As UINT)
   'Copy memory
   Dim i As UINT
   For i = 0 To Length
      ToPtr[i] = FromPtr[i]
   Next i   
End Sub

Private Sub MD5_Internal_UI2UB (OutputPtr As UByte Ptr, InputPtr As UINT Ptr, Length As UINT)
   'Converts UINT memory to UByte memory
   Dim i As Short, j As Short
   
   i = 0: j = 0
   Do While j < Length
      OutputPtr[j] = (InputPtr[i] And &HFF)
      OutputPtr[j+1] = (InputPtr[i] shr 8) And &HFF
      OutputPtr[j+2] = (InputPtr[i] shr 16) And &HFF
      OutputPtr[j+3] = (InputPtr[i] shr 24) And &HFF
      
      i = i + 1
      j = j + 4
   Loop   
End Sub

Private Sub MD5_Internal_UB2UI (OutputPtr As UINT Ptr, InputPtr As UByte Ptr, Length As UINT)
   'Converts UByte memory to UINT memory
   Dim i As Short, j As Short
   
   i = 0: j = 0
   Do While j < Length
      OutputPtr[i] = (InputPtr[j]) Or (InputPtr[j+1] shl 8) Or (InputPtr[j+2] shl 16) Or (InputPtr[j+3] shl 24)
      
      j = j + 4
      i = i + 1
   Loop
End Sub

Private Function MD5_Internal_ExecutePrimitiveFunction (x As UINT, y As UINT, z As UINT, OperationNumber As Short) As UINT
   'Executes one of the four primitive MD5 functions
   Select Case OperationNumber
   Case 1 'F
      MD5_Internal_ExecutePrimitiveFunction = ((x And y) Or (Not(x) And z))
   Case 2 'G
      MD5_Internal_ExecutePrimitiveFunction = ((x And z) Or (y And Not(z)))
   Case 3 'H
      MD5_Internal_ExecutePrimitiveFunction = (x Xor y Xor z)
   Case 4 'I
      MD5_Internal_ExecutePrimitiveFunction = (y Or (x Or Not(z)))
   End Select   
End Function

Private Sub MD5_Internal_ExecuteFunction (a As UINT Ptr, b As UINT Ptr, c As UINT Ptr, d As UINT Ptr, BLX As UINT Ptr, ProcKey As UINT, UKey As UINT, OperationNumber As UByte)
   'Executes one of the four MD5 functions using the primitive functions
   Select Case OperationNumber
   Case 1 'FF
      *a = (*a) + MD5_Internal_ExecutePrimitiveFunction(*b, *c, *d, 1) + *BLX + UKey
      *a = MD5_Internal_BitRotate(*a, ProcKey) + *b
   Case 2 'GG
      *a = (*a) + MD5_Internal_ExecutePrimitiveFunction(*b, *c, *d, 2) + *BLX + UKey
      *a = MD5_Internal_BitRotate(*a, ProcKey) + *b
   Case 3 'HH
      *a = (*a) + MD5_Internal_ExecutePrimitiveFunction(*b, *c, *d, 3) + *BLX + UKey
      *a = MD5_Internal_BitRotate(*a, ProcKey) + *b
   Case 4 'II  
      *a = (*a) + MD5_Internal_ExecutePrimitiveFunction(*b, *c, *d, 4) + *BLX + UKey
      *a = MD5_Internal_BitRotate(*a, ProcKey) + *b
   End Select   
End Sub

Private Function MD5_Internal_BitRotate (v As UINT, n As UINT) As UINT
   'Rotates the bits of a UINT left
   MD5_Internal_BitRotate = (v shl n) Or (v shr (32 - n))
End Function