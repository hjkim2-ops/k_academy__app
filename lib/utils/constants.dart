// 과목 리스트
const List<String> defaultSubjects = [
  '국어',
  '언어와매체',
  '화법과작문',
  '수학',
  '수학I',
  '수학II',
  '미적분',
  '확률과 통계',
  '기하',
  '영어',
];

// 세부내역 리스트
const List<String> defaultDetails = [
  '수강료',
  '교재비',
  '모의고사',
  '독서실비',
  '단체복',
  '식비',
];

// 결제방법 리스트
const List<String> paymentMethods = [
  '카드',
  '계좌이체',
  '현금',
];

// 수업 형태
const List<String> classTypes = [
  '현강',
  '라이브',
];

// Hive box names
const String expenseBoxName = 'expenses';
const String childrenBoxName = 'children';
const String businessNamesBoxName = 'businessNames';
const String instructorsBoxName = 'instructors';
const String customSubjectsBoxName = 'customSubjects';
const String customDetailsBoxName = 'customDetails';
const String cardNamesBoxName = 'cardNames';
const String customPaymentMethodsBoxName = 'customPaymentMethods';

// Schedule box name
const String scheduleBoxName = 'schedules';

// Hidden/order box names
const String hiddenSubjectsBoxName = 'hiddenSubjects';
const String hiddenDetailsBoxName = 'hiddenDetails';
const String hiddenPaymentMethodsBoxName = 'hiddenPaymentMethods';
const String childNameOrderBoxName = 'childNameOrder';

// 시간표 색상 팔레트
const List<int> scheduleColorValues = [
  0xFFA2CFFE, // Blue
  0xFFB2E2C8, // Green
  0xFFFFD6A5, // Orange
  0xFFD4B8E0, // Purple
  0xFFFFB7B2, // Pink
  0xFFA8DCD1, // Teal
  0xFFF5C6AA, // Deep Orange
  0xFFBCC5CE, // Blue Grey
  0xFFC9B09E, // Brown
  0xFFB2E2F2, // Cyan
];

// "기타" 및 "새로 추가" 상수
const String etcOption = '기타';
const String addNewOption = '+ 새로 추가';
