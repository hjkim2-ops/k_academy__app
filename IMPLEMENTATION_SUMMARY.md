# K학원 지출 관리 앱 - 구현 완료

## ✅ 구현 완료 사항

### Phase 1: Foundation Setup
- ✅ `pubspec.yaml`에 모든 필요한 패키지 추가
  - table_calendar, hive, hive_flutter, provider, uuid, intl
- ✅ `expense.dart` 데이터 모델 생성 (13개 필드)
- ✅ Hive 어댑터 생성 완료
- ✅ `constants.dart` 생성 (과목, 세부내역, 결제방법 등)
- ✅ `storage_service.dart` 생성 (Hive 초기화 및 관리)

### Phase 2: Services Layer
- ✅ `expense_service.dart` - CRUD 작업
- ✅ `dropdown_history_service.dart` - 드롭다운 히스토리 관리
- ✅ `date_utils.dart` - 날짜 헬퍼 함수

### Phase 3: State Management
- ✅ `expense_provider.dart` - 지출 상태 관리
- ✅ `dropdown_provider.dart` - 드롭다운 옵션 상태 관리

### Phase 4: Utilities
- ✅ `formatters.dart` - ThousandsSeparatorInputFormatter 구현

### Phase 5: Reusable Widgets
- ✅ `amount_input_field.dart` - 콤마 포맷터가 있는 금액 입력
- ✅ `custom_dropdown_field.dart` - "새로 추가" 기능이 있는 드롭다운
- ✅ `expense_input_dialog.dart` - 11개 필드가 있는 지출 입력 다이얼로그

### Phase 6: Screens
- ✅ `splash_screen.dart` - 2.5초 스플래시 화면
- ✅ `calendar_screen.dart` - 메인 달력 화면 (강사명 표시)

### Phase 7: Main App Integration
- ✅ `main.dart` 업데이트 - Hive 초기화, Provider 설정

## 📁 프로젝트 구조

```
lib\
├── main.dart
├── models\
│   ├── expense.dart
│   └── expense.g.dart (생성됨)
├── services\
│   ├── storage_service.dart
│   ├── expense_service.dart
│   └── dropdown_history_service.dart
├── providers\
│   ├── expense_provider.dart
│   └── dropdown_provider.dart
├── screens\
│   ├── splash_screen.dart
│   └── calendar_screen.dart
├── widgets\
│   ├── expense_input_dialog.dart
│   ├── custom_dropdown_field.dart
│   └── amount_input_field.dart
└── utils\
    ├── constants.dart
    ├── formatters.dart
    └── date_utils.dart
```

## 🎯 주요 기능

### 1. 스플래시 화면
- "K학원" 텍스트 큰 글씨로 표시
- 2.5초 후 자동으로 달력 화면으로 전환
- 로딩 인디케이터 표시

### 2. 메인 달력 화면
- TableCalendar 위젯 사용
- 현재 월의 달력 표시
- 날짜 선택 가능
- 지출이 있는 날짜에 강사명 표시 (최대 2개 + 나머지 개수)
- 선택한 날짜의 지출 목록을 아래에 표시
- 오른쪽 아래 '+' 플로팅 버튼

### 3. 지출 입력 다이얼로그
11개 필드가 정확한 순서로 구성:

1. **자녀** - CustomDropdownField (히스토리 + 새로 추가)
2. **결제일** - DatePicker (선택한 날짜 기본값)
3. **상호** - CustomDropdownField (히스토리 + 새로 추가)
4. **과목** - Dropdown (기본 10개 + 커스텀 추가)
5. **강사** - CustomDropdownField (히스토리 + 새로 추가)
6. **세부내역** - Dropdown (기본 6개 + 커스텀 추가)
7. **현강/라이브** - Radio buttons
8. **결제방법** - Dropdown (카드, 계좌이체, 현금)
   - 카드 선택 시: 카드명 입력란 표시
9. **금액** - AmountInputField (천 단위 콤마 자동)
10. **취소금액** - AmountInputField (선택 사항)
11. **환불여부** - Checkbox

### 4. 데이터 영속성
- Hive를 사용한 로컬 저장
- 6개의 Box 사용:
  - `expenses` - 지출 데이터
  - `children` - 자녀명 히스토리
  - `businessNames` - 상호 히스토리
  - `instructors` - 강사명 히스토리
  - `customSubjects` - 커스텀 과목
  - `customDetails` - 커스텀 세부내역

### 5. 상태 관리
- Provider 패턴 사용
- ExpenseProvider: 날짜별 지출 관리
- DropdownProvider: 드롭다운 옵션 관리

## 🔧 기술 스택

- **Flutter SDK**: 3.11.0+
- **table_calendar**: ^3.0.9 - 달력 UI
- **hive**: ^2.2.3 - 로컬 데이터베이스
- **hive_flutter**: ^1.1.0 - Flutter용 Hive
- **provider**: ^6.1.1 - 상태 관리
- **uuid**: ^4.0.0 - 고유 ID 생성
- **intl**: ^0.19.0 - 날짜/숫자 포맷팅

## 🚀 실행 방법

### Web (Chrome)
```bash
cd C:\Users\kangkim\k_academy__app
flutter run -d chrome
```

### Windows Desktop
```bash
flutter run -d windows
```

### 빌드
```bash
# Web
flutter build web

# Windows
flutter build windows
```

## ✅ 테스트 체크리스트

### 스플래시 화면
- ✅ 앱 시작 시 "K학원" 표시
- ✅ 2-3초 후 자동으로 달력 화면 이동

### 달력 화면
- ✅ 현재 월 달력 표시
- ✅ 날짜 선택 가능
- ✅ '+' 플로팅 버튼 표시

### 입력 다이얼로그
- ✅ '+' 버튼 탭 시 다이얼로그 열림
- ✅ 선택한 날짜가 결제일에 기본값으로 설정
- ✅ 자녀, 상호, 강사 드롭다운에서 "새로 추가" 작동
- ✅ 과목, 세부내역에 기본 옵션 + 커스텀 추가 가능
- ✅ 결제방법 "카드" 선택 시 카드명 입력란 표시
- ✅ 금액 입력 시 콤마 자동 생성
- ✅ 현강/라이브 라디오 버튼 작동
- ✅ 환불여부 체크박스 작동

### 데이터 표시
- ✅ 저장 후 달력에 강사명 표시
- ✅ 선택한 날짜의 지출 목록 표시
- ✅ 지출 상세 정보 카드로 표시

### 데이터 영속성
- ✅ Hive 데이터베이스 초기화 성공
- ✅ 6개 Box 모두 생성 완료

## 📝 다음 단계 (향후 개선사항)

1. **지출 수정/삭제 기능**
   - 지출 카드 탭 시 수정 다이얼로그
   - 스와이프로 삭제

2. **통계 및 보고서**
   - 월별 합계
   - 자녀별, 과목별 통계
   - 차트 (파이차트, 막대그래프)

3. **데이터 내보내기**
   - CSV/Excel 내보내기
   - 백업/복원 기능

4. **고급 기능**
   - 반복 지출 자동 입력
   - 사진 첨부 (영수증)
   - 다크 모드

## 🐛 알려진 이슈

- Flutter SDK 3.32+ 버전에서 RadioListTile의 groupValue/onChanged 파라미터가 deprecated 되었으나, 기능상 문제없이 작동함
- 패키지 이름에 이중 언더스코어(`k_academy__app`)가 있어 경고가 발생하나, 기능상 문제없음

## 📚 코드 하이라이트

### ThousandsSeparatorInputFormatter
- 실시간으로 숫자 입력 시 천 단위 콤마 자동 추가
- 커서 위치 자동 조정

### CustomDropdownField
- 기존 히스토리 + "새로 추가" 옵션
- AlertDialog로 새 항목 추가
- Provider를 통해 히스토리 자동 저장

### Calendar Event Display
- eventLoader로 날짜별 지출 로드
- markerBuilder로 강사명 표시 (최대 2개 + 카운트)
- 날짜별 지출 목록 표시

## 🎉 구현 완료!

모든 계획된 기능이 성공적으로 구현되었습니다. 앱은 현재 Chrome 브라우저에서 실행 중이며, 모든 기본 기능이 정상 작동합니다.
