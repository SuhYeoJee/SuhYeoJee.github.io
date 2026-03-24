---
title: AutoHotkey 드래그 앤 드롭 파일 이름 변경기
description: ""
date: 2026-03-24T01:33:56.383Z
preview: ""
tags:
    - AutoHotkey
categories:
    - Utility
series:
    - AutoHotkey 유틸리티
---

밥은 매일 먹는데 영수중 파일명을 내가 매일 바꿔야한다고.  
그런 건 귀찮아.  

---

## 1. 주요 기능
- **드래그 앤 드롭**: GUI 창 위로 파일을 끌어다 놓으면 즉시 실행됩니다.
- **날짜/항목/성함 지정**: 
   1. `DatePicker`: 오늘 날짜 자동 선택 (YYMMDD 형식 추출)
   2. `ComboBox`: 자주 쓰는 항목(식대, 도서구입비 등) 선택 및 **직접 입력** 가능
   3. `Edit`: 사용자 이름 설정
- **확장자 유지**: 원본 파일이 `.png`든 `.jpg`든 기존 형식을 그대로 유지합니다.
- **중복 방지 (Smart Rename)**: 이미 같은 이름의 파일이 폴더에 있다면, 자동으로 `_2`, `_3` 접미사를 붙여 충돌을 방지합니다.
- **무중단 작업**: 작업 완료 시 `MsgBox` 대신 `ToolTip`을 띄워 흐름이 끊기지 않습니다.

---

## 2. 전체 코드 (AutoHotkey v2)

```autohotkey
#Requires AutoHotkey v2.0

myGui := Gui("+AlwaysOnTop", "파일 이름 변경기")
myGui.SetFont("s10", "맑은 고딕")

myGui.Add("Text", "w80", "날짜 선택:")
dtPicker := myGui.Add("DateTime", "vSelectedDate w200", "ShortDate")

myGui.Add("Text", "w80", "항목 분류:")
cbList := myGui.Add("ComboBox", "vCategory w200 Choose1", ["식대", "도서구입비", "사무용품비"])

myGui.SetFont("s8 cGray")
myGui.Add("Text", "xp y+2", "(목록에 없으면 직접 입력하세요)")

myGui.SetFont("s10 cDefault")
myGui.Add("Text", "w80 y+15", "사용자 이름:")
userName := myGui.Add("Edit", "vUserName w200", "서여지")

myGui.SetFont("s8 cGray")
myGui.Add("Text", "Center w200 y+20", "파일을 여기로 드래그하세요")
myGui.Show("w240")

myGui.OnEvent("DropFiles", Gui_DropFiles)

Gui_DropFiles(GuiObj, GuiCtrlObj, FileArray, X, Y) {
    vDate := dtPicker.Value
    vCat := cbList.Text
    vName := userName.Value
    
    if (vCat = "" || vName = "") {
        MsgBox("분류와 이름을 모두 입력해주세요.", "알림", "Icon!")
        return
    }

    formattedDate := SubStr(vDate, 3, 6)

    for i, FilePath in FileArray {
        SplitPath(FilePath, &FileName, &FileDir, &FileExt)
        
        ; 기본 파일명 생성
        BaseName := formattedDate "_" vCat "_" vName
        NewFileName := BaseName "." FileExt
        NewFilePath := FileDir "\" NewFileName
        
        ; --- 중복 체크 로직 시작 ---
        counter := 2
        while FileExist(NewFilePath) {
            ; 파일이 존재하면 이름 뒤에 _2, _3 등을 붙여서 다시 확인
            NewFileName := BaseName "_" counter "." FileExt
            NewFilePath := FileDir "\" NewFileName
            counter++
        }
        ; --- 중복 체크 로직 끝 ---
        
        try {
            FileMove(FilePath, NewFilePath)
        } catch Error as e {
            MsgBox("파일 이동 중 오류 발생: " e.Message)
        }
    }
    ToolTip("변경 완료!")
    SetTimer(() => ToolTip(), -2000) ; 2초 뒤 툴팁 제거
}

myGui.OnEvent("Close", (*) => ExitApp())
```