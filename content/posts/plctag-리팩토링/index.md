---
title: FlexiPLC - PlcTag 리팩토링
description: ObservableObject과 record
date: 2026-04-01T02:39:22.833Z
preview: ""
tags:
    - C#
categories:
    - Refactoring
series:
    - FlexiPLC 리팩토링
---

뭐냐 이 신세계는.  
설계 끝내고 코드 작성 시작했는데,  
ObservableObject와 record라는 것을 사용하게 됨.  

1. `ObservableObject`: 프라이빗 속성 앞에 사용하면 해당하는 퍼블릭 속성과 속성 수정 전,후 이벤트를 자동생성함. 
2. `record`: 수정하지 않는 데이터 묶음. 값이 같으면 비교에서 같음, `with`로 복사.

--- 

## 1. ObservableObject

### 용도

기존 `INotifyPropertyChanged`를 이용한 속성 변경 이벤트 전달의 보일러플레이트[^1] 를 **소스 제너레이터**로 컴파일 타임에 자동생성. 

[^1]: 보일러플레이트: 수정없이 반복해서 쓰는 코드



### before & after

``` csharp
    public class PlcTag : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;
        private object? _value;
        public object? Value
        {
            get => _value;
            set
            {
                _value = value;
                UpdateDisplayValue();
                OnPropertyChanged(nameof(Value));
            }
        }
```

``` csharp
    public partial class PlcTag : ObservableObject
    {
        [ObservableProperty] private object? _value;
        partial void OnValueChanged(object? value)
        {
            UpdateDisplayValue();
        }
    }
```




### 활용법 (패턴)


| 구성 요소 | 역할 |
|-----------|------|
| `ObservableObject` | `INotifyPropertyChanged` / `INotifyPropertyChanging` 구현 베이스 |
| `[ObservableProperty]` | private 필드에 붙이면 **public 속성**과 변경 알림 코드가 생성됨 |


1.클래스가 `ObservableObject`를 상속합니다.

```csharp
public partial class PlcTag : ObservableObject
{
    // ...
}
```

`partial`[^2]이 **필수**입니다. 제너레이터가 같은 타입의 다른 partial 조각에 멤버를 붙입니다.

[^2]: `partial`: 말 그대로 전체 중 일부임을 나타냄. 다른 부분에 이어붙여서 동작하게 됨. 사용하지 않는 경우 덮어쓰거나 오류.

2. 바인딩 대상 필드에 `[ObservableProperty]`를 붙입니다. 명명 규칙은 **private 필드 `_camelCase` → public 속성 `PascalCase`** 입니다.

```csharp
[ObservableProperty] private object? _value;
[ObservableProperty] private string? _displayValueString;
```

빌드 후에는 대략 다음과 같은 속성이 생성됩니다(개념적으로).

```csharp
public object? Value
{
    get => _value;
    set => SetProperty(ref _value, value);
}
```

3. 값이 바뀔 때 **추가 로직**이 필요하면 `On{PropertyName}Changed` **partial 메서드**를 구현합니다.

```csharp
partial void OnValueChanged(object? value)
{
    UpdateDisplayValue();
}
```

이전 수동 구현에서는 `Value`의 setter 안에서 `UpdateDisplayValue()`와 `OnPropertyChanged`를 같이 호출했지만, Toolkit을 쓰면 **partial 훅으로 분리**할 수 있어 setter가 짧아집니다.

### 무엇이 줄어드는가

- `PropertyChanged` 이벤트 선언
- `OnPropertyChanged([CallerMemberName] ...)` 헬퍼
- 각 속성마다 긴 `get`/`set` + `nameof`

대신 **코드 생성에 의존**하므로, IDE에서 “정의로 이동” 시 생성 파일(보통 `obj` 아래)을 열어 동작을 확인하는 습관이 도움이 됩니다.


---

## 2. C# `record`의 용도

### 용도

`record`(특히 **위치 매개변수 문법**의 `record`)는 주로 **불변에 가까운 데이터 묶음**을 표현할 때 씁니다.

- **값 동등성**: 같은 필드 값이면 `Equals` / `GetHashCode`가 같게 동작(참조 동등이 아님).
- **`with` 표현식**: 일부만 바꾼 복사본을 만들기 쉬움.

``` csharp
// 이름만 바꾸고 나머지는 똑같은 설정을 만들 때
var newConfig = config with { Name = "NEW_TEMP_PV" };
```

- 의미론적으로 “식별자는 타입+키, 나머지는 속성” 같은 **DTO·설정 스냅샷**에 잘 맞습니다.

### 활용법 (`TagConfig` 예시)

태그 **이름·주소·타입·길이·스케일 옵션**은 통신/설정 단계에서 한 번 정해지고, 런타임에 바뀌는 것은 주로 **현재 값·상태**입니다. 그래서 설정끼리 묶어 `record`로 두면 모델 의도가 분명해집니다.

```csharp
public record TagConfig(
    string Name,
    string Address,
    DataType Type,
    int WordCount = 1,
    int ScalingDecimals = 0,
    int TotalDigits = 1
);
```

- **생성**: `new TagConfig("TEMP_PV", "D100", DataType.Int, WordCount: 2, ScalingDecimals: 2, TotalDigits: 5)`
- **접근**: `config.Name`, `config.ScalingDecimals` — 컴파일러가 만든 init 전용 프로퍼티입니다(위치 매개변수 `record`).

`PlcTag`에서는 `public TagConfig Config { get; init; }`처럼 **객체 생성 후에는 Config 참조 자체를 바꾸지 않는** 형태로 쓸 수 있습니다. “설정”과 “라이브 상태”의 경계가 타입 수준에서 드러납니다.



---

## 3. 두 기술을 함께 쓸 때의 그림

한 문장으로 정리하면 다음과 같습니다.

- **`record TagConfig`**: 바인딩보다는 **설정/식별 데이터의 묶음**(값 의미·동등성).
- **`ObservableObject` + `[ObservableProperty]`**: **화면이 따라와야 하는 라이브 상태**(값, 표시 문자열, 상태 열거형 등).

`UpdateDisplayValue`는 `Value`와 `Config`를 같이 읽습니다. `Value`는 Observable로 바뀔 때마다 알림이 가고, `Config`는 스케일 규칙의 **읽기 전용 입력**으로 쓰입니다. 이런 역할 분리가 MVVM에서 흔한 패턴입니다.

---

## 4. 주의할 점

### `Clone()`과 `MemberwiseClone`

리팩터링 후 `Clone`이 `MemberwiseClone()`을 쓰는 경우, **얕은 복사**입니다. `Value`가 참조 형식이면 두 인스턴스가 같은 객체를 가리킬 수 있습니다. 의도한 것인지, 예전처럼 필드를 새 인스턴스에 복사하는 **깊은 복사**가 필요한지 팀 규칙에 맞게 한 번만 정해 두면 좋습니다.

### 생성자에서 Observable 프로퍼티에 할당

생성자에서 `Value = GetDefaultValue(...)`처럼 할당하면, 제너레이터가 만든 setter 경로를 타므로 **초기에도 `OnValueChanged` 등이 호출될 수 있습니다**. `UpdateDisplayValue`가 그때도 안전한지 확인하세요.

> `_value = GetDefaultValue(...)`로 사용하면 이벤트 발생하지 않음

### Toolkit 패키지

프로젝트에 `CommunityToolkit.Mvvm` NuGet 참조가 있어야 하며, C# 버전과 분석기/제너레이터 설정이 맞는지 빌드 한 번으로 검증하는 것이 좋습니다.

---

## 마치며

- **ComponentModel**: `INotifyPropertyChanged` 구현을 제너레이터에 맡기고, `partial` 훅으로 **값 변경 시 부가 로직**만 남깁니다.
- **record**: 설정·식별 정보를 **값 중심 묶음**으로 표현해, 태그 모델에서 **고정 설정**과 **변하는 상태**를 나눕니다.

PLC·산업용 클라이언트처럼 바인딩이 많은 UI에서는 이 조합이 코드량과 의도 표현 면에서 이득이 큽니다. 같은 패턴을 ViewModel에도 그대로 확장할 수 있다는 점도 Toolkit의 장점입니다.

---

## 참고

- [MVVM 도구 키트 개요 (Microsoft Learn)](https://learn.microsoft.com/dotnet/communitytoolkit/mvvm/)
- [ObservableProperty 특성](https://learn.microsoft.com/dotnet/communitytoolkit/mvvm/generators/observableproperty)
- [C# 레코드 형식](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record)
