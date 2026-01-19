---
title: AutoHotkey 60:40 확률형 랜덤 mp3 플레이어
description: ""
date: 2026-01-19T08:21:17.323Z
preview: ""
tags: ["AutoHotkey"]
categories: []
series: []
---


왜 세상에는 방금 나온 갓곡을 한 번 더 틀어주는 플레이어가 없는 걸까. 

---

## 1. 주요 기능
- **확률형 재생:** 노래 한 곡이 끝나면 **60% 확률로 방금 들은 곡을 다시 재생**하고, **40% 확률**로 다른 곡을 선택합니다.
- **백그라운드 실행:** 플레이어 창이 뜨지 않아 작업에 방해되지 않습니다.
- **간편한 제어:** 단축키로 일시정지, 강제 다음 곡 넘기기가 가능합니다.

---

## 2. 전체 코드 (AutoHotkey v2)

`MusicFolder` 경로에 mp3 파일을 넣고 실행. 

``` AHK

#Requires AutoHotkey v2.0
#SingleInstance Force

; ================= 설정 구역 =================
MusicFolder := "C:\음악\폴더\경로"  ; <-- 실제 음악 폴더 경로
RepeatChance := 60                   ; 반복 확률 (%)
; ============================================

; 배경에서 돌아갈 플레이어 객체 생성 (창이 뜨지 않음)
Player := ComObject("WMPlayer.OCX.7")
Player.settings.volume := 50  ; 볼륨 설정 (0~100)

Playlist := []
CurrentSong := ""

; 폴더 내 mp3 파일 목록 불러오기
Loop Files, MusicFolder "\*.mp3"
{
    Playlist.Push(A_LoopFileFullPath)
}

if (Playlist.Length = 0) {
    MsgBox "폴더에 MP3 파일이 없습니다! 경로를 확인해주세요."
    ExitApp
}

Loop {
    ; 1. 재생할 곡 결정 로직
    if (CurrentSong == "") {
        CurrentSong := Playlist[Random(1, Playlist.Length)]
    } else {
        if (Random(1, 100) <= RepeatChance) {
            ; 60% 확률로 같은 곡 유지 (변화 없음)
        } else {
            ; 40% 확률로 다른 곡 선택
            NewSong := CurrentSong
            while (NewSong == CurrentSong && Playlist.Length > 1) {
                NewSong := Playlist[Random(1, Playlist.Length)]
            }
            CurrentSong := NewSong
        }
    }

    ; 2. 음악 재생 시작
    Player.url := CurrentSong
    Player.controls.play()

    ; 3. 노래가 끝날 때까지 대기 (창 없이 상태만 체크)
    ; playState 1은 중지(끝남), 8은 미디어 끝 도달
    while (Player.playState != 1 && Player.playState != 8) {
        Sleep 1000
    }
}

; --- 단축키 설정 ---
; F7: 일시정지 / 다시 재생
F7:: {
    if (Player.playState = 3) ; 재생 중이면
        Player.controls.pause()
    else
        Player.controls.play()
}

; F8: 다음 곡으로 강제 넘기기 (확률 로직 적용됨)
F8:: Player.controls.stop()

; Esc: 프로그램 완전히 종료
Esc:: ExitApp
```