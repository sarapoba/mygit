# 12. 데이터 모델 및 이벤트 설계

> 엔티티 스키마·분석 이벤트 택소노미·북극성(WCU) 산식·KPI 대시보드·실험 인프라·개인정보 원칙의 SSOT.
> 도메인 규칙 자체는 스트릭·프리즈 → 06, AI 코치 → 09, 챌린지 → 10, 온보딩 퍼널 순서 → 07 문서가 SSOT이며, 이 문서는 그 규칙을 담는 데이터 구조와 측정 방법을 확정한다. 화면 플로우 → 11 문서 참조.

## 1. 공통 규칙

- **ID**: 전 엔티티 UUIDv7(클라이언트 생성 — 로컬 우선 아키텍처에서 오프라인 생성 가능, 시간 정렬). 쓰기 API는 클라 생성 ID를 멱등키로 사용해 재동기화 중복을 차단.
- **시간**: 저장은 UTC 타임스탬프 + `tz_offset_min`, 날짜 귀속은 로컬 04:00 하루 경계의 `local_date` 필드(→ 06 문서 §2). 판정·잔디·이벤트의 "오늘"은 전부 `local_date`.
- **원장/파생 분리 (확정)**: 사실 원장 = CheckIn·FreezeLedger·DewLedger·Purchase·Verification — 불변(append-only), 정정은 역분개 행 추가. 파생 상태 = DayOutcome·Streak·Character.level — 원장에서 언제든 멱등 재계산 가능. 06 엣지 12(오프라인 이틀 뒤 동기화 → 스트릭 복원)의 구현 전제다.
- **동기화 충돌**: 체크인 합집합·설정 LWW → 05 문서 §5.1 준용. 분석 이벤트는 로컬 큐 적재 후 배치 업로드 — 제품 데이터와 파이프라인 분리, 소량 유실 허용. **분석 식별자**는 `analytics_id`(설치 시 생성, 가명) 단일 기준이며 user_id와의 매핑 테이블은 분석 저장소 밖에 격리 보관(§8).

## 2. 핵심 엔티티

관계: User 1:N Device·Habit·Purchase·ChallengeEntry, 1:1 Character·FreezeInventory·Subscription. Habit 1:1 HabitSchedule, 1:N CheckIn·DayOutcome·Streak(습관 스트릭) — 전체 데일리 스트릭은 habit_id=null인 Streak 행. Challenge 1:N ChallengeEntry 1:N Verification.

### 2.1 코어 도메인 (Phase 0)

| 필드 | 타입 | 설명 |
|---|---|---|
| **User** | | 계정. 게스트도 User 행(auth_provider=guest) — 가입은 행 승격이지 재생성이 아님 |
| user_id | uuid | PK |
| auth_provider / auth_subject | enum(guest·kakao·apple·google·email) / text | 소셜 식별자. 게스트는 subject=null |
| tier | enum(free·trial·premium) | Subscription에서 파생된 캐시 — 권위는 Subscription |
| diagnosis | jsonb {area, time, chrono} | 온보딩 3문항(→ 07 문서 §2) |
| status / onboarding_completed_at / tz_pass_used_year | enum(active·deletion_pending·deleted) / timestamptz / smallint | 온보딩 영구 플래그(→ 07 §7) + 타임존 PASS 연 3회 카운터(→ 06 엣지 4) |
| **Device** | | 푸시·위젯 상태의 단위 |
| device_id / platform / push_token / notif_state | uuid / enum(ios·android) / text / enum(granted·denied·throttled) | throttled = 3일 무반응 하향(→ 03 문서 §6) |
| **Habit** | | 습관. 무료 3개 제한은 status=active 행 수로 서버 검증. source_routine_id(uuid null)로 라이브러리 출처 기록 |
| habit_id / user_id | uuid | |
| name / mini_name | text | mini_name = 2분 버전(필수, → 06 §5). **자유 텍스트 — 분석 이벤트로 미전송(§8)** |
| type / goal | enum(daily·weekly_n·weekday·quantity·timer) / jsonb | goal = 목표 수량·시간·단위(수량/타이머형만) |
| freeze_equipped | bool (default true) | 프리즈 장착 토글(→ 06 §4.1) |
| status / graduated_at | enum(active·paused·archived·trashed) / timestamptz | 66일 졸업 = archived + graduated_at 기록. trashed는 30일 후 영구 삭제 배치 |
| **HabitSchedule** | | Habit 1:1. 편집은 LWW |
| weekly_n / weekdays / reminder_local_time / paused_until | smallint(1~6) / bit(7) / time / date | 주N회·요일지정형 전용 필드 + 일시정지 프리셋 3/7/14/30일(→ 06 §6) |
| **CheckIn** | | 사실 원장. UNIQUE(habit_id, local_date) — 같은 날 부분→완전 승격은 §1 불변 원칙의 **명시적 예외**(grade 상향 UPDATE만 허용, checkin_completed 이벤트로 이력 보존). 그 외 정정·언체크는 취소 행 추가 |
| checkin_id / habit_id | uuid | checkin_id가 멱등키 |
| local_date | date | 04:00 경계 적용 귀속일 — 새벽 1시 체크는 전날 |
| checked_at_utc / tz_offset_min | timestamptz / smallint | 판정 재현·시계 조작 검증용(→ 06 엣지 11) |
| grade / value / source | enum(full·partial·bonus) / numeric / enum(app·widget·timer·backfill) | bonus = 비지정일 체크, value = 수량·초, backfill = 소급(어제만, → 06 §3) |
| **DayOutcome** | | 파생 원장. UNIQUE(habit_id, local_date). 04:00 배치가 기록, 재계산 멱등 — PENDING은 D+1 경계 재판정으로 종결 |
| result | enum(DONE_F·DONE_P·FROZEN·PENDING·RECOVERED·MISSED·PASS·NOT_DUE) | 06 §4.2 의사코드의 mark()가 쓰는 값 전부. 잔디·last14·복귀율의 단일 출처 |
| decided_at / recompute_ver | timestamptz / int | 재계산 이력 추적 |
| **Streak** | | 파생. habit_id=null 행 = 전체 데일리 스트릭(→ 06 §4.4) |
| habit_id / unit / current / best / last_counted_date | uuid null / enum(day·week) / int / int / date | unit=week는 주N회형(→ 06 §4.3). best는 보관·졸업 후에도 보존 |
| **FreezeInventory + FreezeLedger** | | 계정 공유 재화(→ 06 §4.1). Inventory는 Ledger 합산 캐시 |
| balance / shards / cap | smallint | cap: 무료 2 / 프리미엄 6, 조각 5개 = 1개 |
| Ledger: delta / reason / ref | smallint / enum(monthly_grant·ad·purchase·shard_merge·shard_grant·quest_reward·challenge_reward·auto_consume·backfill_refund·compensation) / (habit_id, local_date) | 소모·반환의 감사 추적 — 소급 체크 시 반환(06 엣지 7)이 역분개 행. shard_grant = 드랍·퀘스트·챌린지의 조각 지급(→ 03 §4·10 §2), 조각은 shards 필드에 별도 합산 |
| **RecoveryCredit** | | 회복권·부활 티켓 통합 원장. revive_ticket은 7일 무접속 윈백 1회(→ 03 §8) |
| kind / period / granted_at / used_at / ref_habit_id | enum(monthly_recovery·revive_ticket) / char(7) / timestamptz ×2 / uuid | monthly_recovery는 UNIQUE(user_id, period) — 유저당 월 1회를 스키마로 강제 |

### 2.2 성장·재화 (Phase 1~2)

| 필드 | 타입 | 설명 |
|---|---|---|
| **Character** | | 루티. User 1:1, 계정당 1명(→ 08 §1) |
| xp_total / level / stage | int / smallint / smallint(1~7) | stage는 래칫 — 하향 UPDATE 금지 제약(→ 08 §2). 감정 상태는 미저장(표현 레이어, → 08 §9) |
| dew_balance / equipped / presets | int / jsonb | 이슬(변동은 DewLedger: delta / reason enum — 획득·소모처는 06 §8.2·08 §7) + 슬롯별 장착 item_id·프리셋 2종(→ 08 §6) |
| **CosmeticItem** (카탈로그) | | 운영 등록 마스터 |
| item_id / slot | uuid / enum(pot·bg·deco_front·deco_back·hat) | 렌더 레이어 → 08 §6 |
| source / price_dew / pack_sku / season_id | enum(dew_shop·cash_pack·season_free·reward) / smallint / text / text | 팩 전용과 이슬 상점 상호 배타(→ 08 §7.2) |
| **CosmeticOwnership** | | UNIQUE(user_id, item_id) — 중복 획득 방지 |
| acquired_via / acquired_at | enum / timestamptz | 시즌 아이템 영구 보유(→ 08 §8) |

### 2.3 수익화·챌린지 (Phase 1~2)

| 필드 | 타입 | 설명 |
|---|---|---|
| **Subscription** | | 권위 = 스토어 서버 알림(App Store Server Notification / Play RTDN) 수신 원장. 클라 자기 보고는 낙관 표시용 |
| product / store | enum(monthly·yearly·yearly_promo) / enum(app_store·play) | 가격 → 02 문서 §2.2 |
| status | enum(trial·active·grace·paused·canceled·expired) | paused = 3개월 일시정지(→ 03 §8), 데이터·스트릭 보존 |
| trial_ends_at / renews_at / pause_until / original_tx_id | timestamptz ×3 / text | trial_ends_at −1일 = D-1 알림 트리거. tx_id는 복원·기기 변경 시 계정 연결 키 |
| **Purchase** | | 단품 원장(프리즈 단품·코스메틱 팩·챌린지 운영비·보증금) |
| sku / amount_krw / status / is_escrow | text / int / enum(paid·refunded·chargeback) / bool | chargeback 웹훅 → 챌린지 즉시 실격(→ 10 §7-8). 보증금 = escrow, 매출 아님(→ 10 §4.1) |
| **Challenge** | | 상품. 상태 머신 → 10 §3 |
| kind / state | enum(practice·official·group) / enum(DRAFT·RECRUITING·ACTIVE·REVIEW·SETTLED·RETRO·CANCELLED) | 전이는 단방향만 허용 |
| rules | jsonb | 인증 방식·빈도·시간대·보증금·정원 — 게시 후 불변(스냅숏) |
| deposit_krw / starts_on / capacity_min_max | int / date / int2range | |
| **ChallengeEntry** | | 참가. UNIQUE(challenge_id, user_id) |
| state | enum(active·withdrawn·disqualified·settled) | |
| achieved / exempt / total_rounds | smallint | 달성률 = achieved ÷ (total − exempt)(→ 10 §4.2) |
| deposit_krw / fee_krw / refund_krw / prize_krw / ladder_tier | int ×4 / smallint | 정산 산식 결과(CS·세무 감사 추적) + 보증금 사다리 단계(→ 10 §2) |
| **Verification** | | 인증 원장. Entry 1:N |
| round_no / method | smallint / enum(photo·checkin_link·timer·steps·watch) | |
| media_key / submitted_at | text / timestamptz | 암호화 스토리지 키. **정산 종결 후 90일 파기 배치**(→ 10 §10-5) |
| status / layers | enum(pending·accepted·rejected·exempt·invalid) / jsonb | layers = 3중 검증 층별 판정(meta·peer·ai, → 10 §6.2) |

## 3. 06 스트릭 규칙 ↔ 데이터 정합 확인

결론: **06의 전 규칙이 CheckIn 원장 + DayOutcome 파생 + 자원 원장 3종으로 신규 개념 추가 없이 표현되며**, 유일한 시한부 상태(PENDING)도 D+1 경계 재판정 배치로 닫혀 상태 머신에 고아가 없다.

| 06 규칙 | 데이터 표현 |
|---|---|
| 프리즈 자동 소모(사전 장착) | Habit.freeze_equipped + FreezeLedger(auto_consume, ref=습관·날짜) + DayOutcome=FROZEN |
| "한 번은 사고" 유저당 월 1회 | RecoveryCredit UNIQUE(user, period)로 스키마 강제. PENDING → (D+1 달성·수락) RECOVERED / (미달) MISSED |
| 부분 달성 동일 인정 | CheckIn.grade=partial → DONE_P. 스트릭 판정은 DONE_F와 동일 취급, XP 차등은 원장에만 |
| 소급 체크 1일 + 프리즈 반환 | CheckIn.source=backfill(local_date=어제만 서버 검증) + backfill_refund 역분개 + 해당일 재판정 |
| 주N회형 주 스트릭 | Streak.unit=week, 월 04:00 주 마감 배치. 해당 습관의 일별 DayOutcome은 NOT_DUE |
| 전체 데일리 스트릭 | Streak(habit_id=null) — due 중 1개 이상 DONE이면 +1, 전부 유지 장치면 유지 |
| 7/21/66 마일스톤·졸업 | streak_milestone_reached 이벤트(파생) + Habit.graduated_at |
| 타임존 PASS 연 3회 | DayOutcome=PASS + User.tz_pass_used_year |
| 오프라인 지연 동기화 복원(엣지 12) | 원장 불변 + DayOutcome·Streak 전체 재계산(recompute_ver 증가) — 멱등 |
| AI 컨텍스트 last14(→ 09 §3) | DayOutcome 14일 직렬화(O·P·F·R·X·-) — 별도 저장 없음, 표기 1:1 대응 |

## 4. 분석 이벤트 택소노미

**네이밍 컨벤션 (확정)**: snake_case 영문, `{객체}_{행동 과거형}` (예: `checkin_completed`). 화면 노출 `_viewed`, 발송 `_sent`, 열람 `_opened`, 제안 `_offered`/`_accepted`/`_declined`. 07 문서 §8의 온보딩 이벤트명과 09 문서 §6.2의 `coach_*` 이벤트명은 이미 이 컨벤션이며 **재명명 없이 그대로 채택**한다.
**공통 속성(전 이벤트 자동 부착)**: analytics_id, session_id, platform, app_version, tier, days_since_join, local_date, ab_buckets[]. 아래 표의 속성은 이벤트 고유분만. **자유 텍스트(습관명·회고·생성 카피)는 어떤 이벤트에도 싣지 않는다** — habit_id 등 ID만(§8).

| 이벤트 (패밀리 46행 — `/` = 동일 계열 변형, 변형 포함 80+종) | 트리거 | 주요 속성 |
|---|---|---|
| **온보딩** (전체 목록·순서 → 07 §8) | | |
| onboarding_start | S01 렌더 | entry(fresh·resume) |
| diagnosis_q1/q2/q3_answered | 선택 즉시 | answer |
| routine_selected / routine_custom_created / habit_confirmed | S06 CTA ~ S07 확정 | routine_id, is_custom, habit_id, habit_type |
| shrink_offered / shrink_accepted / shrink_declined | S08 | variant(제안형·확인형) |
| first_checkin_completed / first_check_skipped | S09~S10 | is_starter_mission |
| notify_prime_accepted/declined, notify_os_granted/denied | S11~S12 | default_time, reprompt_count |
| widget_added / widget_pitch_skipped | S13 | os |
| onboarding_completed / abandoned / resumed | 상태 머신 전이 | last_step, elapsed_s |
| signup_prompt_viewed / signup_completed | 07 §5 트리거 | trigger(d2·d7·forced), provider |
| guest_data_migrated | 이관 완료 | merged_into_existing, habit_count |
| **코어 루프** | | |
| app_opened | 콜드 스타트·포그라운드 복귀 | source(icon·push·widget·deeplink) |
| habit_created / habit_edited | 저장 완료 | habit_id, type, from_routine_id / changed_fields |
| habit_paused/resumed/archived/graduated/deleted | 일시정지·재개·보관·66일 졸업·휴지통(→ 06 §6) | preset_days, final_streak |
| checkin_completed / checkin_undone | 체크 성립(위젯·타이머·소급 포함) / 언체크(앱 내만) | habit_id, grade(full·partial·bonus), source(app·widget·timer·backfill), streak_after, xp |
| reward_drop_received | 체크인 추첨 결과 — **전량 로깅(확률 검증용)** | drop(reaction·xp5·xp2x·dew·shard), pity_count |
| weekly_quest_completed | 주간 퀘스트 달성(→ 03 §4) | quest_id, reward |
| report_weekly_viewed / report_monthly_viewed | 리포트 열람 | period_id, dwell_s |
| **스트릭·프리즈** | | |
| streak_milestone_reached | 7·21·66일 도달 | habit_id, days |
| streak_frozen | 04:00 배치 프리즈 자동 소모 | habit_id, freeze_left |
| streak_recovery_offered / streak_recovery_accepted | 회복 카드 노출·수락 | habit_id |
| streak_broken | streak=0 확정 | habit_id, lost_days, cause(no_resource·pending_fail·second_miss) |
| streak_revived | 부활 티켓 사용 | restored_days |
| freeze_granted / freeze_refunded / freeze_purchased | 지급(정기·조각·광고·보상) / 소급 반환 / 단품 결제 | source(monthly·shard·ad·compensation·purchase), sku, price_krw |
| **페이월·구독** | | |
| paywall_viewed / paywall_dismissed | 확정 3 타이밍 + 맥락 변형(→ 02 §2.3) / 닫기 버튼 | trigger(streak3·habit4·report·freeze — 11 §3.4 ctx enum과 단일 사전, 통계 잠금 카드는 report), layout, dwell_ms |
| paywall_error | 가격 로딩 실패·타임아웃·폴백 표시 | error_type — **04 게이트 "페이월 결함 0건"의 카운터** |
| trial_started / trial_d1_notified | 체험 개시 / 종료 D-1 알림 발송 | product |
| subscription_started / subscription_renewed | 스토어 서버 알림 수신 | product, price_krw |
| subscription_pause_accepted / subscription_canceled | 해지 플로우(→ 03 §8) | reason(해지 설문 선택값) |
| purchase_completed | 단품·코스메틱 팩 결제 확정 | sku, price_krw |
| **캐릭터** | | |
| character_stage_reached / character_petted | 단계 상승 연출 / 쓰다듬기 — 애착 지표(→ 08 §4) | stage(1~7) / daily_first |
| cosmetic_acquired / cosmetic_equipped | 획득 / 장착 | item_id, via(dew·pack·season·reward) / slot |
| dew_earned / dew_spent | 이슬 원장 변동 | amount, reason |
| season_quest_completed | 시즌 퀘스트(→ 08 §8) | season_id |
| **챌린지** (Phase 2) | | |
| challenge_viewed / challenge_joined | 상세 진입 / 예치 결제 완료 | challenge_id, kind, deposit_krw |
| verification_submitted | 인증 제출 | method, round_no |
| verification_rejected / peer_review_completed | 층별 부결 / 상호 검증 응답 | layer(meta·peer·ai), reason_code / verdict, latency_h |
| challenge_withdraw_clicked / challenge_withdrawn | 포기 버튼 / 만류 개입 후 확정 | achieved_rate — 만류 효과(→ 10 §9) 측정 |
| challenge_completed / challenge_settled | 개인 결과 확정 / 정산 지급 | achieved_rate, outcome(full·refund85·partial) / refund_krw, prize_krw |
| challenge_appeal_filed | 이의신청 접수(REVIEW) | round_no |
| **알림·AI 코치** | | |
| notification_sent / notification_opened / notification_throttled | 발송 / 탭 / 3일 무반응 하향 발동(→ 03 §6) | kind(reminder·streak_risk·winback·trial_d1·report), habit_id |
| coach_briefing_sent / coach_briefing_opened | 아침 브리핑(→ 09 §2.1) | cache_hit |
| coach_intervention_sent / coach_intervention_converted | 미루기 개입 / 2시간 내 해당 습관 체크 | habit_id |
| coach_downshift_offered / coach_downshift_accepted | 난이도 제안 카드(상향 포함, → 09 §2.4) | action(shrink·reduce_freq·pause7·restore) |
| coach_feedback_negative / coach_fallback_used | "숨기기" / 템플릿 폴백(→ 09 §7) | feature, reason |
| crisis_card_shown | 위기 안내 카드(→ 09 §5.2) | (트리거 텍스트 미수집 — 노출 사실만) |
| **실험** | | |
| experiment_exposed | 처치 차이가 처음 보이는 순간 1회(§6) | experiment, variant |

## 5. 북극성 WCU 산식 (확정)

**WCU = 해당 주에 checkin_completed ≥ 1건인 유저(analytics_id) 수.**

| 항목 | 확정 |
|---|---|
| 주 경계 | 유저 로컬 **월요일 04:00 ~ 차주 월요일 04:00** — 06 §2·§4.3의 제품 주 경계와 동일(제품의 "주"와 지표의 "주"를 분리하지 않는다). 대시보드 주 라벨은 KST 기준 |
| 포함 | grade full·partial·bonus 전부, source 앱·위젯·타이머·소급 전부(소급은 귀속 local_date의 주로 계산). 게스트 포함 |
| 제외 | 스타터 미션(습관이 아닌 1회성, → 07 §4), FROZEN·RECOVERED·PASS만으로 유지된 주(유지 장치는 체크인이 아니다), 삭제 유예·삭제 유저 |
| 확정 시점 | 주 종료 +48시간 스냅숏 고정(오프라인 지연 동기화 흡수, → 06 엣지 12). 이후 도착분은 소급 갱신하되 공표치는 스냅숏 기준 |

## 6. KPI 대시보드 — 03·04 문서 KPI 1:1 매핑

**활성 정의 (확정)**: 활성 = `app_opened ∪ checkin_completed`. 앱 오픈만으로 정의하면 위젯 원탭 전용 유저(핵심 설계 타깃)가 이탈로 잘못 집계된다. Dn 리텐션의 D0 = onboarding_start의 local_date.

| 지표 (출처) | 산식 | 목표 |
|---|---|---|
| **WCU** (04 북극성) | §5 | 추이 관리(절대 목표는 코호트 규모 종속) |
| D1 / D7 / D30 (03 §9) | 설치 코호트 중 n일째 로컬 날짜에 활성인 비율 | 45% / 25% / 15% (베타 게이트 D7 15%, P1 게이트 D30 8%) |
| 첫 주 체크인 완료율 (03 §9) | D0~D6 코호트 합산: Σ DONE(F+P) due일 ÷ Σ 전체 due일 (DayOutcome 기준) | 65% (베타 게이트 50%) |
| 스트릭 7일+ 도달률 (03 §9) | 가입 28일 내 streak_milestone_reached(days=7) 발생 유저 비율 | 35% |
| 복귀율 (03 §9) | 분모 = DayOutcome ∈ {FROZEN, PENDING, MISSED} 발생 유저·일, 분자 = 익일 checkin_completed | 55% |
| 체험 시작률 / 체험→유료 (02 §3, 04 게이트) | trial_started ÷ 설치 / subscription_started ÷ trial_started | 9% / 25%(게이트)~35% |
| 12개월 유지율 (02 §3) | 구독 개시 코호트의 12개월 시점 status=active·paused 비율 | 40% |
| 페이월 결함 (04 P1 게이트) | paywall_error 건수 + 페이월 화면 크래시 | **0건** |
| 챌린지 완주율 / 참가자 D30 델타 (04 P2 게이트) | challenge_completed(outcome=full·refund85) ÷ entry / 참가자 vs 성향 매칭 비참가자 D30 | ≥ 60% / +10%p |
| AI 코치 운영 지표 | → 09 문서 §6.2 (오픈율·전환율·수락률·숨기기·리젝률) | 09 준용 |

대시보드 보드 구성 4장: ① 북극성·리텐션(WCU + Dn + 완료율·복귀율·7일 도달률, 시즌 코호트 분리 축 필수 — 04 리스크 "신년 코호트 왜곡") ② 수익화(체험 퍼널·ARPU·해지/일시정지) ③ 안정성(paywall_error·크래시 프리 99.8%, → 05 §5.2) ④ 챌린지 운영(→ 10 §11 지표 표 준용).

## 7. A/B 실험 인프라

- **할당 단위 = analytics_id.** 결정적 해시 `hash(experiment_key + analytics_id) % 1000` → 버킷. 원격 플래그 + 로컬 캐시로 동작해 **네트워크 없이도 배정 가능** — 온보딩 실험이 07 §7-6(온보딩 무네트워크 원칙)과 충돌하지 않는 조건. 게스트→가입 시 analytics_id가 유지되므로(§8) 버킷·퍼널 연속성 보장.
- **노출 이벤트**: `experiment_exposed`는 처치 차이가 유저에게 처음 보이는 순간 1회만 발화. 분석은 노출 유저 기준이 기본이되, 처치가 노출 시점 자체를 바꾸는 실험(아래 3번)은 할당 코호트 기준. 상호 배타 레이어 3개(온보딩/페이월/코어 루프)로 실험 간 오염을 방지하고, 판정은 최소 2주(주간 루프 1사이클 포함) + 사전 등록 지표만.

| 04 실험 | 할당 시점 | 노출 이벤트 시점 | 판정 지표(산식은 §6) |
|---|---|---|---|
| 1. 용서 장치 on/off | 온보딩 완료 | 첫 DayOutcome ∈ {FROZEN, PENDING, MISSED} 발생 시(장치가 실제 개입하는 순간 — 민감도 확보) | D30, 복귀율 |
| 2. 캐릭터 유무 | 설치(첫 실행) | onboarding_start(S01부터 루티 노출) | D30, 세션 빈도, character_petted(daily_first). 대조군은 XP·드랍 동일(→ 08 §9-8) |
| 3. 페이월 타이밍 3종 | 온보딩 완료 | paywall_viewed — 단 **판정 분모는 할당 코호트**(타이밍 자체가 처치라 노출이 내생적) | 체험 시작률, D7 |
| 4. 극소 습관 강제 축소 | 온보딩 진입 | shrink_offered(S08 도달) | 첫 주 체크인 완료율 |
| 5. 연간 우선 vs 월간 우선 | 온보딩 완료 | paywall_viewed | 체험→유료, 90일 ARPU |

## 8. 개인정보·보안

| 항목 | 확정 방침 |
|---|---|
| 수집 최소화 | 필수 수집 = 소셜 인증 식별자(+이메일), 푸시 토큰뿐. 실명·생년월일(챌린지 성인 확인은 결제 수단 검증으로 대체, → 10 §7-10)·전화번호·연락처·상시 위치 미수집. 진단 3문항·습관 데이터는 서비스 제공 목적 내에서만 처리 |
| 자유 텍스트 격리 | 습관명·루틴명·한 줄 회고는 제품 DB에만 저장. **분석 이벤트·서드파티 SDK로 원문 전송 금지**(이벤트는 ID만, §4). AI 프롬프트 투입 범위·회고 opt-in·로그 30일 파기는 → 09 문서 §3 5원칙 전면 준용 — coach_* 이벤트도 메타데이터만 적재하고 생성문 원문은 미적재 |
| 건강 관련 데이터 | Phase 0~1은 자기 보고 체크인만(센서 미수집 — 05 Non-goal #6). Phase 2 워치·걸음수(→ 10 §6)는 민감정보 **별도 동의** + 인증 판정 전용(분석·마케팅 사용 금지, HealthKit/Health Connect 약관 준수) + 원본 미보관(판정 결과만 Verification.layers에 기록). 인증 사진은 정산 종결 후 90일 파기(→ 10 §10-5) |
| 게스트→가입 이전 | 로컬 전량 이관·병합 규칙 → 07 문서 §5 준용. analytics_id는 가입 후에도 동일 유지, user_id 매핑 행만 추가 — 매핑 테이블은 분석 저장소 밖 격리(§1). 게스트 기간 데이터도 동일한 최소화 원칙 적용 |
| 삭제 요청 | 앱 내 탈퇴 → 즉시 로그인 차단 + 30일 복구 유예(status=deletion_pending) → 영구 삭제 배치: 제품 DB 삭제 + **analytics_id↔user 매핑 파기로 이벤트 비식별화** + 미디어 파기. 예외: 결제·정산 기록은 전자상거래법 보존 기간(5년) 동안 분리 보관, 챌린지 정산 진행 중이면 SETTLED 후 실행. 처리 SLA: 유예 종료 후 7일 내 완료 |
| 보안 | 전송 TLS, 저장 시 서버측 암호화(인증 미디어는 키 분리), 운영자 접근 최소 권한 + 접근 로그. AI 벤더 zero-retention 계약(→ 09 §3-5) |
