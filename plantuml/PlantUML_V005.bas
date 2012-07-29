'  ========================================================================
'  Plantuml : a free UML diagram generator
'  ========================================================================
'
'  (C) Copyright 2009, Arnaud Roques
'
'  Project Info:  http://plantuml.sourceforge.net
'
'  This file is part of Plantuml.
'
'  Plantuml is free software; you can redistribute it and/or modify it
'  under the terms of the GNU General Public License as published by
'  the Free Software Foundation, either version 3 of the License, or
'  (at your option) any later version.
'
'  Plantuml distributed in the hope that it will be useful, but
'  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
'  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
'  License for more details.
'
'  You should have received a copy of the GNU General Public
'  License along with this library; if not, write to the Free Software
'  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
'  USA.
'
'  [Java is a trademark or registered trademark of Sun Microsystems, Inc.
'  in the United States and other countries.]
'
'  Original Author:  Arnaud Roques
'  Word Macro: Alain Bertucat / Matthieu Sabatier
'  Improved error management : Christopher Fuhrman
'  Version 005

Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)

Const startuml = "@start"
Const enduml = "@end"

' =========================================================
' This function returns the path for plantuml.jar
Function getJarPath() As String
    Set fs = CreateObject("Scripting.FileSystemObject")
    nbTemplates = ActiveDocument.Parent.Templates.Count
    mainPath = ActiveDocument.Path
    try = ActiveDocument.Path & "\"
    
    nb = InStrRev(mainPath, "\")
    Do While nb > 1 And fs.FileExists(mainPath + "\plantuml.jar") = False
        mainPath = Left(mainPath, nb - 1)
        try = try & vbCrLf & mainPath & "\"
        nb = InStrRev(mainPath, "\")
    Loop
    
    For i = 1 To nbTemplates
        If fs.FileExists(mainPath + "\plantuml.jar") = False Then
            mainPath = ActiveDocument.Parent.Templates.Item(i).Path
            try = try & vbCrLf & ActiveDocument.Parent.Templates.Item(i).Path & "\"
            nb = InStrRev(mainPath, "\")
            Do While nb > 1 And fs.FileExists(mainPath + "\plantuml.jar") = False
                mainPath = Left(mainPath, nb - 1)
                try = try & vbCrLf & mainPath & "\"
                nb = InStrRev(mainPath, "\")
            Loop
        End If
    Next i
    
    If fs.FileExists(mainPath + "\plantuml.jar") Then
        getJarPath = mainPath
    Else
        getJarPath = "Error : Cannot find plantuml.jar in :" & vbCrLf & try
    End If
    
End Function

' =========================================================
' Print out the used plantuml.jar
Sub ShowPlantumlJarPath()
    Set fs = CreateObject("Scripting.FileSystemObject")
    jarPath = getJarPath()
    If fs.FileExists(jarPath & "\plantuml.jar") Then
        MsgBox "OK : " & jarPath & "\plantuml.jar"
    Else
        MsgBox jarPath
    End If
End Sub
' =========================================================
' Used to migrate from previous PlantUML macro version
Sub RemoveOldVersionPlantUMLSyles()
   On Error GoTo DeleteEnd
   ActiveDocument.Styles("PlantUML").Delete
   On Error GoTo 0
DeleteEnd:
   On Error GoTo 0
   Call Macro_UML_all

End Sub
' =========================================================
' Called when the user click on "UML.*"
Sub Macro_UML_all()
    Macro_UML ("all")
End Sub

' =========================================================
' Called when the user click on "UML.1"
Function Macro_UML_parg()
    Macro_UML ("parg")
End Function

' =========================================================

Function Macro_UML(scope)
' Generate diagrams image from a PlantUML source textual description in the Word Document
' Scope can be "parg" or "all"
'
' - Initialisations
'
     Call ToolbarInit
    Set statusButton = CommandBars("UML").Controls(6)
    
    Call CreateStyle
    Call CreateStyleImg
    Call ShowPlantuml

    Call ShowHiddenText
    Selection.Range.Select
'
' documentId is the filename with its path, without extension
'
    documentId = ActiveDocument.Name
    documentId = Left(documentId, Len(documentId) - 4)
    
    ' Check for the presente of plantuml.jar
    
    Set fs = CreateObject("Scripting.FileSystemObject")
    jarPath = getJarPath()
    If fs.FileExists(jarPath & "\plantuml.jar") = False Then
        MsgBox jarPath
        GoTo Macro_UML_exit
    End If
    
' - Phase 1
' We create a file text per bloc of diagrams
' We look for @startuml
' We open the textfile in background (visible:=false)
' We add to the name a number on 4 digit
' The text bloc is put on "PlantUML" style
' Then the bloc is copied into the text file

    statusButton.Caption = "Extract"
    statusButton.Visible = False
    statusButton.Visible = True
    If scope = "all" Then
        Set parsedText = ActiveDocument.Content
        isForward = True
    Else
        Set parsedText = Selection.Range
        parsedText.Collapse
        isForward = False
    End If

    parsedText.Find.Execute FindText:=startuml, Forward:=isForward
    If parsedText.Find.Found = True Then
        'We keep the the first line only "@startuml" with the carriage return
        Set singleParagraph = parsedText.Paragraphs(1).Range
        singleParagraph.Collapse
    Else
        GoTo Macro_UML_exit
    End If
    
    Do While parsedText.Find.Found = True And _
             (scope = "all" Or currentIndex < 1)
        statusButton.Caption = "Extract." & currentIndex + 1
        statusButton.Visible = False
        statusButton.Visible = True
        Set currentParagraph = parsedText.Paragraphs(1)
        Set paragraphRange = currentParagraph.Range
        paragraphRange.Collapse
        jobDone = False
        Do Until jobDone
            If Left(currentParagraph.Range.Text, Len(startuml)) = startuml Then
                Set paragraphRange = currentParagraph.Range
                paragraphRange.Collapse
               
            End If
            paragraphRange.MoveEnd Unit:=wdParagraph
            If Left(currentParagraph.Range.Text, Len(enduml)) = enduml Then
                paragraphRange.Style = "PlantUML"
                paragraphRange.Copy
                Set textFile = Documents.Add(Visible:=False)
                textFile.Content.Paste
                currentIndex = currentIndex + 1
                textFileId = documentId & "_extr" & Right("000" & currentIndex, 4) & ".txt"
                textFile.SaveAs FileName:=jarPath & "\" & textFileId, FileFormat:=wdFormatText, Encoding:=65001
                textFile.Close
                jobDone = True
            End If
            
            Set currentParagraph = currentParagraph.Next
            
            If currentParagraph Is Nothing Then
                jobDone = True
            End If
        Loop
        parsedText.Collapse Direction:=wdCollapseEnd
        If scope = "all" Then
            parsedText.Find.Execute FindText:=startuml, Forward:=True
        End If
   Loop
'
' We create a lock file that will be deleted by the Java program to indicate the end of Java process
'
    statusButton.Caption = "Gener"
    statusButton.Visible = False
    statusButton.Visible = True
    Set lockFile = Documents.Add(Visible:=False)
    lockFile.SaveAs FileName:=jarPath & "\javaumllock.tmp", FileFormat:=wdFormatText
    lockFile.Close

'
' Call to PlantUML to generate images from text descriptions
'
    javaCommand = "java -classpath """ & jarPath & "\plantuml.jar;" & _
            jarPath & "\plantumlskins.jar"" net.sourceforge.plantuml.Run -charset UTF8 -word """ & jarPath & "/"""
    Shell (javaCommand)
' This sleep is needed, but we don't know why...
    Sleep 500
'
' Phase 2 :
' Insertion of images into the word document
' We insert the image after the textual block that describe the diagram
'
    jobDone = False
    currentIndex = 0
    
' We wait for the file javaumllock.tmp to be deleted by Java
' which means that the process is ended
'
    Do
        currentIndex = currentIndex + 1
        statusButton.Caption = "Gener." & currentIndex
        statusButton.Visible = False
        statusButton.Visible = True
        DoEvents
        Sleep 1000
        If fs.FileExists(jarPath & "\javaumllock.tmp") = False Then
            jobDone = True
            Exit Do
        End If
        If currentIndex > 30 Then
            statusButton.Visible = False
            MsgBox ("Java Timeout. Aborted.")
            Exit Do
        End If
    Loop
    
    If jobDone = False Then
        End
    End If
        
    statusButton.Caption = "Inser"
    statusButton.Visible = False
    statusButton.Visible = True
    
    If scope = "all" Then
        Set parsedText = ActiveDocument.Content
        isForward = True
    Else
        Set parsedText = singleParagraph
        isForward = True
    End If
    parsedText.Find.Execute FindText:=enduml, Forward:=isForward
    currentIndex = 0
    Do While parsedText.Find.Found = True And (scope = "all" Or currentIndex < 1)
        currentIndex = currentIndex + 1
        statusButton.Caption = "Inser." & currentIndex
        statusButton.Visible = False
        statusButton.Visible = True
        On Error GoTo LastParagraph
        Set currentParagraph = parsedText.Paragraphs(1).Next.Range
        Do While currentParagraph.InlineShapes.Count > 0 And currentParagraph.Style = "PlantUMLImg"
            currentParagraph.Delete
            Set currentParagraph = parsedText.Paragraphs(1).Next.Range
        Loop
        On Error GoTo 0
        Set currentRange = currentParagraph
        imagesDirectory = jarPath & "\" & documentId & "_extr" & Right("000" & currentIndex, 4) & "*.png"
        image = Dir(imagesDirectory)
        While image <> ""
            ' Contain the text of the error
            errorTextFile = jarPath & "\" & Left(image, Len(image) - 4) & ".err"
            Set currentParagraph = ActiveDocument.Paragraphs.Add(Range:=currentRange).Range
            Set currentRange = currentParagraph.Paragraphs(1).Next.Range
            currentParagraph.Style = "PlantUMLImg"
            currentParagraph.Collapse
            
            Set image = currentParagraph.InlineShapes.AddPicture _
                (FileName:=jarPath & "\" & image _
                , LinkToFile:=False, SaveWithDocument:=True)
                                
            If fs.FileExists(errorTextFile) Then
                image.AlternativeText = LoadTextFile(errorTextFile)
                Beep
            Else
                image.AlternativeText = "Generated by PlantUML"
            End If

            If image.ScaleHeight > 100 Or image.ScaleWidth > 100 Then
                image.Reset
            End If
            image = Dir()
        Wend
        parsedText.Collapse Direction:=wdCollapseEnd
        parsedText.Find.Execute FindText:=enduml, Forward:=True
   Loop
    
'
' Phase 3 : suppression of temporary files (texte and PNG)
'
Phase3:
    statusButton.Caption = "Delete"
    statusButton.Visible = False
    statusButton.Visible = True
    On Error Resume Next
    Kill (jarPath & "\" & documentId & "_extr*.*")
    On Error GoTo 0

Macro_UML_exit:

    statusButton.Visible = False
    
    'We show the hidden description text
    Call ShowHiddenText
    DoubleCheckStyle
Exit Function


' This is need when the very last line of the Word document is @enduml
LastParagraph:
    Selection.EndKey Unit:=wdStory
    Selection.TypeParagraph
    Selection.ClearFormatting
    
        imagesDirectory = jarPath & "\" & documentId & "_extr" & Right("000" & currentIndex, 4) & "*.png"
        image = Dir(imagesDirectory)
        While image <> ""
            ' Contain the text of the error
            errorTextFile = jarPath & "\" & Left(image, Len(image) - 4) & ".err"
            
            Set currentParagraph = ActiveDocument.Paragraphs.Add.Range
            Set currentRange = currentParagraph.Paragraphs(1).Next.Range
            currentParagraph.Style = "PlantUMLImg"
            currentParagraph.Collapse
            
            Set image = currentParagraph.InlineShapes.AddPicture _
                (FileName:=jarPath & "\" & image _
                , LinkToFile:=False, SaveWithDocument:=True)
                
            If fs.FileExists(errorTextFile) Then
                image.AlternativeText = LoadTextFile(errorTextFile)
                Beep
            Else
                image.AlternativeText = "Generated by PlantUML"
            End If
            
            If image.ScaleHeight > 100 Or image.ScaleWidth > 100 Then
                image.Reset
            End If
            image = Dir()
        Wend
    
    'Resume Next
    GoTo Phase3

End Function

' =========================================================
' Initialize the plantuml ToolBar
Function ToolbarInit()

    On Error GoTo ToolbarCreation
    Set toolBar = ActiveDocument.CommandBars("UML")
    On Error GoTo 0
    toolBar.Visible = True
    
    On Error GoTo ButtonAdd
    Set currentButton = toolBar.Controls(1)
    On Error GoTo 0
    currentButton.OnAction = "Module1.SwitchP"
    currentButton.Style = msoButtonCaption
    currentButton.Caption = Chr(182)
    currentButton.Visible = True
    
    On Error GoTo ButtonAdd
    Set currentButton = toolBar.Controls(2)
    On Error GoTo 0
    currentButton.OnAction = "Module1.ShowPlantuml"
    currentButton.Style = msoButtonCaption
    currentButton.Caption = "Show PlantUML"
    currentButton.Visible = True
    
    On Error GoTo ButtonAdd
    Set currentButton = toolBar.Controls(3)
    On Error GoTo 0
    currentButton.OnAction = "Module1.HidePlantuml"
    currentButton.Style = msoButtonCaption
    currentButton.Caption = "Hide PlantUML"
    currentButton.Visible = True
    
    On Error GoTo ButtonAdd
    Set currentButton = toolBar.Controls(4)
    On Error GoTo 0
    currentButton.OnAction = "Module1.Macro_UML_all"
    currentButton.Style = msoButtonCaption
    currentButton.Caption = "UML.*"
    currentButton.Visible = True
    
    On Error GoTo ButtonAdd
    Set currentButton = toolBar.Controls(5)
    On Error GoTo 0
    currentButton.OnAction = "Module1.Macro_UML_parg"
    currentButton.Style = msoButtonCaption
    currentButton.Caption = "UML.1"
    currentButton.Visible = True
    
    On Error GoTo ButtonAdd
    Set currentButton = toolBar.Controls(6)
    On Error GoTo 0
    currentButton.OnAction = ""
    currentButton.Style = msoButtonCaption
    currentButton.Caption = "Trace"
    currentButton.Visible = True
    Exit Function

ToolbarCreation:
    Set toolBar = ActiveDocument.CommandBars.Add(Name:="UML")
    Resume Next

ButtonAdd:
    Set currentButton = toolBar.Controls.Add(Type:=msoControlButton, Before:=toolBar.Controls.Count + 1)
    Resume Next

End Function

' =========================================================
' We need to double check that the style is present in the document
Function DoubleCheckStyle()
    CreateStyle
    CreateStyleImg
    Set myStyle = ActiveDocument.Styles("PlantUML")
    myStyle.BaseStyle = ActiveDocument.Styles.Item(1).BaseStyle
    
    myStyle.AutomaticallyUpdate = True
    With myStyle.Font
        .Name = "Courier New"
        .Size = 9
        .Hidden = False
        .Hidden = True
        .Color = wdColorGreen
    End With
End Function

' =========================================================
Function CreateStyle()
    On Error GoTo CreateStyleAdding
    Set myStyle = ActiveDocument.Styles("PlantUML")
    Exit Function
CreateStyleAdding:
    Set myStyle = ActiveDocument.Styles.Add(Name:="PlantUML", Type:=wdStyleTypeParagraph)
    myStyle.BaseStyle = ActiveDocument.Styles.Item(1).BaseStyle
    myStyle.AutomaticallyUpdate = True
    With myStyle.Font
        .Name = "Courier New"
        .Size = 9
        .Hidden = False
        .Hidden = True
        .Color = wdColorGreen
    End With
    With myStyle.ParagraphFormat
        With .Shading
            .Texture = wdTextureNone
            .ForegroundPatternColor = wdColorAutomatic
            .BackgroundPatternColor = wdColorLightGreen
        End With
        
        .LeftIndent = CentimetersToPoints(0)
        With .Shading
            .Texture = wdTextureNone
            .ForegroundPatternColor = wdColorAutomatic
            .BackgroundPatternColor = 12254650
        End With
        With .Borders(wdBorderLeft)
            .LineStyle = wdLineStyleDashLargeGap
            .LineWidth = wdLineWidth050pt
            .Color = 3910491
        End With
        With .Borders(wdBorderRight)
            .LineStyle = wdLineStyleDashLargeGap
            .LineWidth = wdLineWidth050pt
            .Color = 3910491
        End With
        With .Borders(wdBorderTop)
            .LineStyle = wdLineStyleDashLargeGap
            .LineWidth = wdLineWidth050pt
            .Color = 3910491
        End With
        With .Borders(wdBorderBottom)
            .LineStyle = wdLineStyleDashLargeGap
            .LineWidth = wdLineWidth050pt
            .Color = 3910491
        End With
        With .Borders
            .DistanceFromTop = 1
            .DistanceFromLeft = 4
            .DistanceFromBottom = 1
            .DistanceFromRight = 4
            .Shadow = False
        End With
    End With
    
    ' ajout des tabulations
    myStyle.NoSpaceBetweenParagraphsOfSameStyle = False
    myStyle.ParagraphFormat.TabStops.ClearAll
    myStyle.ParagraphFormat.TabStops.Add Position:= _
        CentimetersToPoints(1), Alignment:=wdAlignTabLeft, Leader:=wdTabLeaderSpaces
    myStyle.ParagraphFormat.TabStops.Add Position:= _
        CentimetersToPoints(2), Alignment:=wdAlignTabLeft, Leader:=wdTabLeaderSpaces
    myStyle.ParagraphFormat.TabStops.Add Position:= _
        CentimetersToPoints(3), Alignment:=wdAlignTabLeft, Leader:=wdTabLeaderSpaces
    myStyle.ParagraphFormat.TabStops.Add Position:= _
        CentimetersToPoints(4), Alignment:=wdAlignTabLeft, Leader:=wdTabLeaderSpaces


End Function

' =========================================================
Function CreateStyleImg()
    On Error GoTo CreateStyleImgAdding
    Set myStyle = ActiveDocument.Styles("PlantUMLImg")
    myStyle.BaseStyle = ActiveDocument.Styles.Item(1).BaseStyle
    On Error GoTo 0
    Exit Function
CreateStyleImgAdding:
    Set myStyle = ActiveDocument.Styles.Add(Name:="PlantUMLImg", Type:=wdStyleTypeParagraph)
    myStyle.AutomaticallyUpdate = True
End Function

' =========================================================
' We show the hidden text
Function ShowPlantuml()
    DoubleCheckStyle

    'WordBasic.ShowComments
    ' We put a bookmark to retrieve position after showing the text
    ActiveDocument.Bookmarks.Add Name:="Position", Range:=Selection.Range
        
    Set myStyle = ActiveDocument.Styles("PlantUML")
    Set toolBar = ActiveDocument.CommandBars("UML")
        
    toolBar.Controls(2).Visible = False
    toolBar.Controls(3).Visible = True
    toolBar.Controls(4).Visible = True
    toolBar.Controls(5).Visible = True
        
    Call ShowHiddenText
        
    'We go back to the bookmark and we delete it
    Selection.GoTo What:=wdGoToBookmark, Name:="Position"
    ActiveDocument.Bookmarks(Index:="Position").Delete
    
End Function


' =========================================================
' MSR - gestion de l'option d'affichage des textes masques du style : "PlantUML"
Function HidePlantuml()
    DoubleCheckStyle
    'WordBasic.ShowComments
    ' We put a bookmark to retrieve position after showing the text
    ActiveDocument.Bookmarks.Add Name:="Position", Range:=Selection.Range
    
    Set myStyle = ActiveDocument.Styles("PlantUML")
    Set toolBar = ActiveDocument.CommandBars("UML")
        
    toolBar.Controls(2).Visible = True
    toolBar.Controls(3).Visible = False
    toolBar.Controls(4).Visible = False
    toolBar.Controls(5).Visible = False
    
    Call HideHiddenText
    
    'We go back to the bookmark and we delete it
    Selection.GoTo What:=wdGoToBookmark, Name:="Position"
    ActiveDocument.Bookmarks(Index:="Position").Delete

End Function

' =========================================================
Function HideHiddenText()
    ActiveDocument.ActiveWindow.View.ShowAll = False
    ActiveDocument.ActiveWindow.View.ShowHiddenText = False
End Function

' =========================================================
Function ShowHiddenText()
    ActiveDocument.ActiveWindow.View.ShowAll = False
    ActiveDocument.ActiveWindow.View.ShowHiddenText = True
End Function

' =========================================================
Function SwitchP()
    flag = Not (ActiveDocument.ActiveWindow.View.ShowTabs)
    ActiveDocument.ActiveWindow.View.ShowParagraphs = flag
    ActiveDocument.ActiveWindow.View.ShowTabs = flag
    ActiveDocument.ActiveWindow.View.ShowSpaces = flag
    ActiveDocument.ActiveWindow.View.ShowHyphens = flag
    ActiveDocument.ActiveWindow.View.ShowAll = False
End Function
 
' =========================================================
' \\ Function to return the full content of a text file as a string
'from http://www.vbaexpress.com/kb/getarticle.php?kb_id=699
Function LoadTextFile(sFile) As String
    Dim iFile As Integer
     
    On Local Error Resume Next
     ' \\ Use FreeFile to supply a file number that is not already in use
    iFile = FreeFile
     
     ' \\ ' Open file for input.
    Open sFile For Input As #iFile
     
     ' \\ Return (Read) the whole content of the file to the function
    LoadTextFile = Input$(LOF(iFile), iFile)
     
    Close #iFile
     
End Function



