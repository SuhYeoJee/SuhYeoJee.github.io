---
title: AutoHotkey 아카이빙 도우미 Arkiver
description: ""
date: 2026-03-26T06:28:30.258Z
preview: ""
draft: true
tags:
    - AutoHotkey
categories:
    - Utility
series:
    - AutoHotkey 유틸리티
---


더 이상 프로젝트 정리를 미룰 수 없다.  
정리 규칙을 만들었고, 저번에 대충 만들었던 [리네이머]({{<relref "autohotkey-드래그-앤-드롭-파일-이름-변경기/index.md">}})를 확장했다. 

---

## 1. 주요 기능
*   **스마트 리네이밍**: 날짜, 성격(Category), 타입(Type)을 조합하여 일관된 네이밍 규칙 적용.
*   **자동 경로 배정**: 선택한 날짜에 맞춰 연도별 폴더(`YYYY`)를 자동 생성하고 이동.
*   **드래그 앤 드롭**: GUI 창 위로 파일이나 폴더를 던지기만 하면 즉시 처리.
*   **실시간 미리보기**: 변경될 파일명을 템플릿 형태로 미리 확인하여 실수 방지.
*   **중복 방지 로직**: 동일한 이름이 있을 경우 순번(`_2`, `_3`)을 자동으로 부여.

### 📂 적용 네이밍 컨벤션
`[YYMM]_[Category]_[OriginalName]_[Type].[Ext]`

---

## 2. 전체 코드 (AutoHotkey v2)

```autohotkey
#Requires AutoHotkey v2.0


; --- 설정 ---
default_root_dir := "C:\Ark\02_Archive"

TraySetIcon("shell32.dll", 4)
arkGui := Gui("-MinimizeBox +AlwaysOnTop", "Arkiver v1.0")
arkGui.SetFont("s10", "맑은 고딕")

labelW := 70

; --- 상단 입력 섹션 ---
arkGui.Add("Text", "w" labelW " h25 +Right", "Root Dir :") 
edtPath := arkGui.Add("Edit", "x+10 w160 ReadOnly", default_root_dir)
arkGui.Add("Button", "x+5 w35 h25", "...").OnEvent("Click", SelectFolder)

arkGui.Add("Text", "xm w" labelW " h25 +Right", "Date :") 
dtPicker := arkGui.Add("DateTime", "x+10 vSelectedDate w200", "ShortDate")
dtPicker.OnEvent("Change", UpdatePreview)

arkGui.Add("Text", "xm w" labelW " h25 +Right", "Category :")
cbCategory := arkGui.Add("ComboBox", "x+10 vCategory w200 Choose1", ["Work", "Personal", "Study"])
cbCategory.OnEvent("Change", UpdatePreview)

arkGui.Add("Text", "xm w" labelW " h25 +Right", "Type :")
cbType := arkGui.Add("ComboBox", "x+10 vType w200 Choose1", ["Integrated", "Code", "Logic", "Media", "Draft", "Model"])
cbType.OnEvent("Change", UpdatePreview)

; --- 하단 미리보기 섹션 ---
arkGui.Add("Text", "xm w305 cGray y+20 Center", "─ Preview ─")

arkGui.SetFont("s10 cBlue Bold")
txtPreview := arkGui.Add("Text", "xm+10 w285 Center y+5", "") 

arkGui.SetFont("s8 cGray Norm")
arkGui.Add("Text", "xm w305 Center y+15", "프로젝트를 드래그하여 아카이브로 전송하세요.")

; 초기 미리보기 실행
UpdatePreview()
arkGui.Show("w305")

; --- 함수부 ---

; 미리보기 갱신
UpdatePreview(*) {
    raw_date := dtPicker.Value 
    date_prefix := SubStr(raw_date, 3, 4)
    cat_short := SubStr(cbCategory.Text, 1, 4)
    type_val := cbType.Text
    
    ; 가상 파일명: [YYMM]_[Cat]_[Proj]_[Type].ext
    txtPreview.Value := date_prefix "_" cat_short "_[    ]_" type_val ".[  ]"
}

; 아카이브 루트 선택
SelectFolder(*) {
    SelectedDir := DirSelect("*" edtPath.Value, 3, "아카이브 루트를 선택하세요")
    if SelectedDir {
        edtPath.Value := SelectedDir
        UpdatePreview()
    }
}

; 드래그 앤 드롭 메인 로직
arkGui.OnEvent("DropFiles", (GuiObj, GuiCtrlObj, FileArray, X, Y) => MoveToArk(FileArray))

MoveToArk(FileArray) {
    root_dir := edtPath.Value
    raw_date := dtPicker.Value 
    target_year := SubStr(raw_date, 1, 4)
    date_prefix := SubStr(raw_date, 3, 4)
    category := cbCategory.Text
    type := cbType.Text
    
    target_year_dir := root_dir "\" target_year
    if !DirExist(target_year_dir)
        DirCreate(target_year_dir)

    for i, FilePath in FileArray {
        SplitPath(FilePath, &FileName, &FileDir, &FileExt, &FileNameNoExt)
        cat_short := SubStr(category, 1, 4)
        base_name := date_prefix "_" cat_short "_" FileNameNoExt "_" type
        
        isDir := DirExist(FilePath)
        new_name := isDir ? base_name : base_name "." FileExt
        target_path := target_year_dir "\" new_name
        
        counter := 2
        while (FileExist(target_path) || DirExist(target_path)) {
            new_name := isDir ? base_name "_" counter : base_name "_" counter "." FileExt
            target_path := target_year_dir "\" new_name
            counter++
        }
        
        try {
            if isDir
                DirMove(FilePath, target_path, "R")
            else
                FileMove(FilePath, target_path, 1)
            ToolTip("📦 Arkive 완료: " new_name)
        } catch Error as e {
            MsgBox("전송 실패: " FileName "`n사유: " e.Message)
        }
    }
    SetTimer(() => ToolTip(), -3000)
}

arkGui.OnEvent("Close", (*) => ExitApp())
```
