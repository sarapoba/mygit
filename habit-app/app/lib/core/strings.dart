/// 전체 카피 SSOT — 기획 07 문서(P0 변형)·03 문서 톤 규칙 준수.
/// 죄책감 어휘·명령형 종결·손실 프레이밍(상실 어휘) 금지. 수정 시 PM+디자이너 승인(13 §6-4).
library;

class Str {
  // 공통
  static const appName = '루트';
  static const cancel = '나중에 할게요';

  // 온보딩 (07 — Phase 0 변형)
  static const obWelcomeTitle = '완벽하지 않아도 괜찮아요.';
  static const obWelcomeSub = '하루 2분, 끊기지 않는 습관을 시작해요.\n놓친 날은 시스템이 지켜줄게요.';
  static const obStart = '시작하기';
  static const obQ1 = '지금 가장 키우고 싶은 건 무엇인가요?';
  static const obQ2 = '습관에 매일 쓸 수 있는 시간은요?';
  static const obQ2Sub = '솔직할수록 좋아요.';
  static const obQ3 = '언제 컨디션이 가장 좋아요?';
  static const obAnalyzing = '딱 맞는 시작을 찾는 중…';
  static const obRecommendTitle = '이렇게 시작하는 걸 추천해요';
  static const obRecommendNote = '욕심내지 않을 거예요 — 첫 주는 딱 하나.\n나머지는 준비되면 다시 권할게요.';
  static const obRecommendCta = '이 루틴으로 시작';
  static const obShrinkTitle = '처음 목표는 작을수록 이겨요.';
  static const obShrinkTitleConfirm = '2분 버전으로 준비해뒀어요.';
  static const obShrinkCta = '2분 버전으로 시작';
  static const obShrinkCtaConfirm = '좋아요';
  static const obShrinkKeep = '원래 크기로 할게요';
  static const obFirstNow = '지금 바로 해볼까요?';
  static const obFirstStarter = '본 게임은 내일이에요.\n오늘은 몸풀기!';
  static const obFirstCta = '했어요!';
  static const obRemindTitle = '내일 몇 시에 알려드릴까요?';
  static const obRemindSub = '잔소리는 안 해요 — 습관 시간에 딱 한 번만.';
  static const obRemindNone = '알림 없이 할게요';
  static const obLandingTitle = '여기가 당신의 정원이에요.';
  static const obEnter = '정원 입장';

  // 홈
  static String riskBanner(int day) => '오늘 $day일째가 될 수 있어요. 2분이면 지킬 수 있어요.';
  static const allDone = '오늘 몫을 전부 해냈어요 🌿';
  static String tomorrowFirst(String name) => '내일 첫 습관: 「$name」';
  static const miniTag = '2분만';
  static String miniHint(String mini) => '2분 버전: $mini';
  static const doneSub = '완료 · 오늘도 해냈어요';
  static const partialSub = '부분 달성 — 오늘로 똑같이 인정돼요';
  static const pendingSub = '지금 하면 어제까지 이어져요';
  static String addHabit(int cur, int max) => '＋ 습관 추가 ($cur/$max)';
  static const slotsFull = '무료 슬롯 3개를 모두 쓰고 있어요 — 4번째부터는 곧 열릴 예정이에요.';

  // 체크 피드백
  static String checkedToast(int streak) => '$streak일째 — 오늘도 자랐어요 🌱';
  static const partialToast = '2분 버전도 훌륭해요 — 오늘로 인정!';
  static const upgradeToast = '완전 달성으로 승격!';
  static const uncheckToast = '체크를 취소했어요';

  // 회복 체크 (06 §4.2 — 죄책감 문구 금지)
  static const recoveryTitle = '어제는 사고였어요.\n스트릭 이어갈까요?';
  static String recoveryBody(String name) =>
      '「$name」 — 이번 달 회복 체크 1회를 쓰면 어제까지의 기록이 그대로 이어져요. '
      '미스 한 번은 사고, 두 번부터가 진짜 끊김이에요.';
  static const recoveryAccept = '스트릭 이어가기';
  static const recoveryDecline = '괜찮아요, 새로 시작할게요';
  static const recoveryAcceptToast = '이어졌어요 — 어제는 없던 일로 🌿';
  static const recoveryDeclineToast = '새 마음으로 1일차부터!';

  // 마일스톤 (7/21/66 — 08 §2.1, P0은 배지 연출만)
  static String milestoneTitle(int days) =>
      days >= 66 ? '66일 — 습관이 뿌리내렸어요' : '$days일을 이어왔어요';
  static String milestoneBody(int days) => days >= 66
      ? '이제 이 습관은 당신의 일부예요. 다음 여정을 시작해볼까요?'
      : '조용히, 확실하게 자라는 중이에요.';
  static const milestoneClose = '계속';

  // 습관 추가/편집
  static const addTitle = '새 습관';
  static const nameLabel = '습관 이름';
  static const nameHint = '예: 홈트 15분';
  static const miniLabel = '2분 버전 (필수) — 처음 목표는 작을수록 이겨요';
  static const miniFieldHint = '예: 운동복 갈아입기';
  static const addCta = '추가하기';
  static const nameNeeded = '습관 이름을 적어주세요';
  static const miniNeeded = '2분 버전이 꼭 필요해요 — 작게 시작해요';
  static String habitAdded(String name) => '「$name」 시작 — 오늘부터 1일차예요';
  static const deleteHabit = '습관 보내주기';
  static const deleteConfirm = '기록은 사라지지 않지만, 이 습관은 목록에서 사라져요. 계속할까요?';

  // 기록
  static const statsTitle = '기록';
  static const grassNote = '미달성일은 빈 칸이에요 — 그날의 달성만 기록해요.';
  static const tileWeekly = '이번 주 달성률';
  static const tileBest = '최장 스트릭';
  static const tileFrozen = '프리즈가 지킴';
  static const freezeLogTitle = '프리즈 기록';
  static const freezeLogEmpty = '아직 기록이 없어요 — 프리즈는 놓친 날 자동으로 스트릭을 지켜요.';

  // 마이
  static const myTitle = '마이';
  static const forgiveness = '용서 장치';
  static const freezeRow = '스트릭 프리즈';
  static String freezeStatus(int bal, int cap) => '$bal/$cap 보유 · 매월 1일 +1';
  static const recoveryRow = '회복 체크 (한 번은 사고)';
  static const recoveryLeft = '이번 달 1회 남음';
  static const recoveryUsed = '이번 달 사용함';
  static const notifSection = '알림';
  static const reminderRow = '리마인더';
  static const reminderNone = '설정 안 함';
  static const themeSection = '테마';
  static const themeLight = '라이트';
  static const themeSystem = '시스템';
  static const themeDark = '다크';
  static const dataSection = '데이터';
  static const resetRow = '데이터 초기화 (온보딩부터 다시)';
  static const resetConfirm = '모든 데이터를 지우고 온보딩부터 다시 시작할까요?';
  static const versionLabel = '루트 v1.0.0 — 하루 2분, 끊기지 않는 습관';
}

/// 진단 선택지 (07 §2).
class Diagnosis {
  static const areas = [
    ('💪', '몸', '운동·수면·식습관을 되찾고 싶어요'),
    ('📚', '공부', '시험·자격증·어학을 준비 중이에요'),
    ('🚀', '일과 성장', '커리어와 사이드 프로젝트를 키우고 싶어요'),
    ('🌿', '마음', '마음의 여유와 안정이 필요해요'),
  ];
  static const times = [
    ('⏱️', '2분', '요즘은 2분도 빠듯해요'),
    ('☕', '10분', '짬은 낼 수 있어요'),
    ('🕐', '30분+', '마음먹으면 확보돼요'),
  ];
  static const chronos = [
    ('🌅', '아침형', '이른 시간에 정신이 맑아요'),
    ('🌙', '저녁형', '밤에 집중이 잘돼요'),
    ('🔀', '그때그때', '일정이 불규칙해요'),
  ];
  static const remindDefaults = {'아침형': '07:00', '저녁형': '20:30', '그때그때': '12:30'};
}

/// 진단 → 루틴 추천 매핑 (07 §3 확정 표).
class RoutinePick {
  const RoutinePick(this.routine, this.habit, this.mini, {this.starterFirst = false});

  final String routine;
  final String habit;
  final String mini;

  /// 시간 고정 습관(기상 등) — 첫 체크 대신 스타터 미션 (07 §4).
  final bool starterFirst;

  static const _map = {
    '몸|아침': RoutinePick('미라클 모닝 스타터', '기상 직후 물 한 잔', '물 한 모금', starterFirst: true),
    '몸|저녁': RoutinePick('퇴근 후 리셋', '홈트 15분', '운동복 갈아입기'),
    '공부|아침': RoutinePick('매일 25분 공부', '책상에 앉아 타이머 25분', '책상에 앉아 책 펴기'),
    '공부|저녁': RoutinePick('매일 25분 공부', '책상에 앉아 타이머 25분', '책상에 앉아 책 펴기'),
    '일과 성장|아침': RoutinePick('1쪽 성장 루틴', '독서 10쪽', '1쪽 읽기'),
    '일과 성장|저녁': RoutinePick('1쪽 성장 루틴', '사이드 프로젝트 30분', '에디터 열고 10분'),
    '마음|아침': RoutinePick('마음 챙김 2분', '명상 5분', '심호흡 3번'),
    '마음|저녁': RoutinePick('마음 챙김 2분', '한 줄 일기', '한 단어 일기'),
  };

  static const starters = {
    '몸': '물 한 잔 마시기',
    '공부': '영단어 1개 소리 내 읽기',
    '일과 성장': '아무 책이나 1쪽 읽기',
    '마음': '눈 감고 심호흡 3번',
  };

  static RoutinePick pick(String area, String chrono) {
    final slot = chrono == '아침형' ? '아침' : '저녁';
    return _map['$area|$slot']!;
  }
}
