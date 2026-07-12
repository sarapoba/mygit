/// 도메인 모델 — 기획 12 문서(데이터 모델)의 Phase 0 부분집합.
/// 순수 Dart: Flutter 의존 없음.
library;

/// 체크인 등급 (12 문서 CheckIn.grade — Phase 0은 full/partial만).
enum Grade { full, partial }

/// 하루 판정 결과 (12 문서 DayOutcome — Phase 0 매일형 부분집합).
enum Outcome { doneFull, donePartial, frozen, pending, recovered, missed }

/// 체크 액션의 결과 이벤트 — UI가 연출·토스트를 결정하는 데 쓴다.
enum CheckEvent { checked, upgraded, unchecked, needsRecovery }

const int freeSlots = 3; // 무료 습관 슬롯 (02 문서)
const int freezeCap = 2; // 무료 프리즈 보유 상한 (06 문서 §4.1)

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.mini,
    required this.created,
    this.freezeOn = true,
  });

  final String id;
  String name;

  /// 2분 버전 — 생성 시 필수 (06 문서 §5).
  String mini;

  /// 생성일 local_date. 이 날짜 이전은 판정 대상이 아니다.
  final String created;

  /// 프리즈 장착 토글 (06 문서 §4.1, 기본 ON).
  bool freezeOn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mini': mini,
        'created': created,
        'freezeOn': freezeOn,
      };

  static Habit fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        mini: j['mini'] as String,
        created: j['created'] as String,
        freezeOn: (j['freezeOn'] as bool?) ?? true,
      );
}

class FreezeEntry {
  FreezeEntry({required this.date, required this.type, required this.message});

  final String date;
  final String type; // grant | use | skip
  final String message;

  Map<String, dynamic> toJson() => {'d': date, 't': type, 'm': message};

  static FreezeEntry fromJson(Map<String, dynamic> j) =>
      FreezeEntry(date: j['d'] as String, type: j['t'] as String, message: j['m'] as String);
}

/// 온보딩 진행 상태 (07 문서 — 전이마다 영속화, 이어하기 보장).
class OnboardingData {
  String step = 'welcome';
  String? area; // 몸 | 공부 | 일과 성장 | 마음
  String? time; // 2분 | 10분 | 30분+
  String? chrono; // 아침형 | 저녁형 | 그때그때
  String? remind; // "HH:MM" 또는 null

  Map<String, dynamic> toJson() =>
      {'step': step, 'area': area, 'time': time, 'chrono': chrono, 'remind': remind};

  static OnboardingData fromJson(Map<String, dynamic> j) => OnboardingData()
    ..step = (j['step'] as String?) ?? 'welcome'
    ..area = j['area'] as String?
    ..time = j['time'] as String?
    ..chrono = j['chrono'] as String?
    ..remind = j['remind'] as String?;
}

/// 앱 전체 상태 — 사실(checks)과 파생(outcomes)을 분리 보관 (12 문서 §1).
class AppState {
  bool obDone = false;
  OnboardingData ob = OnboardingData();
  List<Habit> habits = [];

  /// 사실 원장: local_date → habitId → grade.
  Map<String, Map<String, Grade>> checks = {};

  /// 파생: local_date → habitId → outcome. 04:00 배치가 기록.
  Map<String, Map<String, Outcome>> outcomes = {};

  int freezeBal = 1; // 첫 달 기본 1개 지급 상태로 시작
  List<FreezeEntry> freezeLog = [];

  /// "한 번은 사고" 회복권 사용 월 (유저당 월 1회, 06 문서 §4.1).
  String? recoveryUsedMonth;

  /// 이 local_date까지 판정 완료.
  String? lastJudged;

  String theme = 'system'; // system | light | dark
  int seq = 1;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'obDone': obDone,
        'ob': ob.toJson(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'checks': checks.map((d, m) => MapEntry(d, m.map((id, g) => MapEntry(id, g.name)))),
        'outcomes': outcomes.map((d, m) => MapEntry(d, m.map((id, o) => MapEntry(id, o.name)))),
        'freezeBal': freezeBal,
        'freezeLog': freezeLog.map((e) => e.toJson()).toList(),
        'recoveryUsedMonth': recoveryUsedMonth,
        'lastJudged': lastJudged,
        'theme': theme,
        'seq': seq,
      };

  static AppState fromJson(Map<String, dynamic> j) {
    final s = AppState()
      ..obDone = (j['obDone'] as bool?) ?? false
      ..ob = OnboardingData.fromJson((j['ob'] as Map?)?.cast<String, dynamic>() ?? {})
      ..habits = ((j['habits'] as List?) ?? [])
          .map((e) => Habit.fromJson((e as Map).cast<String, dynamic>()))
          .toList()
      ..freezeBal = (j['freezeBal'] as num?)?.toInt() ?? 1
      ..freezeLog = ((j['freezeLog'] as List?) ?? [])
          .map((e) => FreezeEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList()
      ..recoveryUsedMonth = j['recoveryUsedMonth'] as String?
      ..lastJudged = j['lastJudged'] as String?
      ..theme = (j['theme'] as String?) ?? 'system'
      ..seq = (j['seq'] as num?)?.toInt() ?? 1;
    ((j['checks'] as Map?) ?? {}).forEach((d, m) {
      s.checks[d as String] = (m as Map).map(
          (id, g) => MapEntry(id as String, Grade.values.byName(g as String)));
    });
    ((j['outcomes'] as Map?) ?? {}).forEach((d, m) {
      s.outcomes[d as String] = (m as Map).map(
          (id, o) => MapEntry(id as String, Outcome.values.byName(o as String)));
    });
    return s;
  }
}
