# Royal Puzzle 3 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Royal Match 수준의 Match-3 퍼즐 게임을 Godot 4.x로 구현. "곰사원 회사 탈출" 테마 + 캐슬 데코레이션 메타 루프 + 곰사원 Nightmare 특수 모드.

**Architecture:** Godot 4.x + GDScript, 씬 기반 컴포넌트 아키텍처. 코어 Match-3 엔진 → 부스터/장애물 시스템 → 메타 루프(방 꾸미기) → 특수 모드 순으로 레이어 확장. 이벤트 버스(Signal)로 시스템 간 느슨한 결합.

**Tech Stack:** Godot 4.4, GDScript, GUT(테스트), Mobile Export (iOS/Android)

**Reference:**
- Royal Match 분석 스펙: `/Users/jaejin/projects/toy/game-spec-royal-match-2026-03-10/spec.md`
- Royal Puzzle 2 소스: `/Users/jaejin/projects/toy/royal-puzzle-2/`
- Royal Puzzle 2 계획: `/Users/jaejin/projects/toy/royal-puzzle-2/docs/plans/`

---

## Scope & Phase Overview

이 프로젝트는 6개 독립 Chunk로 분할. 각 Chunk는 자체적으로 동작 가능한 빌드를 생성.

| Chunk | 이름 | 핵심 산출물 | 의존성 |
|-------|------|-----------|--------|
| 1 | Project Bootstrap & Core Engine | Godot 프로젝트 + Match-3 기본 동작 | 없음 |
| 2 | Boosters & Obstacles | 5종 부스터 + 10종 합체 + 6종 장애물 | Chunk 1 |
| 3 | Level System & Progression | 200레벨 생성 + 에리어/별 시스템 | Chunk 2 |
| 4 | UI/UX & Visual Polish | HUD + 메뉴 + 파티클 + 사운드 | Chunk 3 |
| 5 | Meta Loop & Special Modes | 방 꾸미기 + 곰사원 Nightmare | Chunk 4 |
| 6 | Mobile & Deploy | 모바일 최적화 + PWA + 배포 | Chunk 5 |

---

## File Structure

```
royal-puzzle-3/
├── project.godot                     # Godot 프로젝트 설정
├── CLAUDE.md                         # 프로젝트 지침
├── docs/
│   └── superpowers/plans/            # 구현 계획
├── assets/                           # 게임 리소스
│   ├── sprites/
│   │   ├── gems/                     # 6종 보석 (64x64)
│   │   ├── boosters/                 # 5종 부스터 (64x64)
│   │   ├── obstacles/                # 6종 장애물 (64x64)
│   │   ├── ui_boosters/              # 4종 UI 부스터 (48x48)
│   │   ├── characters/               # 곰사원, 악덕사장 (128x128)
│   │   └── rooms/                    # 20개 방 배경
│   ├── audio/
│   │   ├── bgm/                      # 배경음
│   │   └── sfx/                      # 효과음
│   └── fonts/                        # 커스텀 폰트
├── src/
│   ├── autoload/                     # Godot Autoload (싱글톤)
│   │   ├── game_events.gd            # 이벤트 버스 (Signal Hub)
│   │   ├── game_manager.gd           # 게임 상태 관리
│   │   ├── save_manager.gd           # 저장/로드
│   │   └── audio_manager.gd          # 사운드 관리
│   ├── core/                         # 코어 엔진 (순수 로직, 씬 무관)
│   │   ├── board_logic.gd            # 보드 매칭/캐스케이드 로직
│   │   ├── match_detector.gd         # 매치 감지 (3/4/5/L/T/+)
│   │   ├── gravity_handler.gd        # 낙하 (수직 + 대각선)
│   │   ├── booster_rules.gd          # 부스터 생성 규칙
│   │   ├── booster_executor.gd       # 부스터 실행 로직
│   │   ├── booster_merger.gd         # 부스터 합체 (10종)
│   │   ├── obstacle_manager.gd       # 장애물 처리 (3레이어)
│   │   ├── level_generator.gd        # 레벨 자동 생성
│   │   └── types.gd                  # 열거형/상수 정의
│   ├── board/                        # 보드 씬 & 렌더링
│   │   ├── board.tscn                # 보드 루트 씬
│   │   ├── board.gd                  # 보드 컨트롤러
│   │   ├── cell.tscn                 # 셀 씬 (3레이어)
│   │   ├── cell.gd                   # 셀 스크립트
│   │   ├── gem.tscn                  # 보석 씬
│   │   ├── gem.gd                    # 보석 애니메이션/상태
│   │   ├── booster_piece.tscn        # 부스터 피스 씬
│   │   ├── booster_piece.gd          # 부스터 렌더링
│   │   └── input_handler.gd          # 터치/스와이프 입력
│   ├── ui/                           # UI 씬
│   │   ├── hud.tscn                  # 인게임 HUD
│   │   ├── hud.gd                    # HUD 로직
│   │   ├── main_menu.tscn            # 메인 메뉴
│   │   ├── main_menu.gd
│   │   ├── level_select.tscn         # 레벨 선택
│   │   ├── level_select.gd
│   │   ├── result_popup.tscn         # 결과 팝업
│   │   ├── result_popup.gd
│   │   ├── room_view.tscn            # 방 꾸미기 뷰
│   │   ├── room_view.gd
│   │   ├── booster_bar.tscn          # 하단 부스터 바
│   │   └── booster_bar.gd
│   ├── effects/                      # 이펙트
│   │   ├── particle_manager.gd       # 파티클 관리
│   │   ├── match_effect.tscn         # 매치 이펙트
│   │   ├── booster_effect.tscn       # 부스터 이펙트
│   │   └── screen_effect.gd          # 화면 효과 (흔들림, 플래시)
│   ├── meta/                         # 메타 루프
│   │   ├── room_manager.gd           # 방 관리 (20개 공간)
│   │   ├── room_task.gd              # 방 태스크 데이터
│   │   ├── area_progress.gd          # 에리어 진행도
│   │   └── nightmare_mode.gd         # 곰사원 Nightmare 모드
│   └── data/                         # 게임 데이터
│       ├── level_data.gd             # 레벨 데이터 클래스
│       ├── room_data.gd              # 방 데이터 클래스
│       └── levels/                   # 레벨 JSON/리소스
│           ├── level_001.tres ... level_200.tres
├── scenes/                           # 메인 씬
│   ├── game.tscn                     # 게임 메인 씬
│   ├── game.gd
│   └── splash.tscn                   # 스플래시 화면
└── tests/                            # GUT 테스트
    ├── test_match_detector.gd
    ├── test_gravity_handler.gd
    ├── test_booster_rules.gd
    ├── test_booster_executor.gd
    ├── test_booster_merger.gd
    ├── test_obstacle_manager.gd
    ├── test_level_generator.gd
    └── test_board_logic.gd
```

---

## Chunk 1: Project Bootstrap & Core Match-3 Engine

**목표**: Godot 프로젝트 생성 + 8x10 보드에서 기본 Match-3가 동작하는 플레이 가능한 프로토타입

**완료 기준**: 6종 보석 스와이프 교환 → 3매치 감지 → 파괴 → 낙하 → 연쇄 반응이 동작

---

### Task 1.1: Godot 프로젝트 초기화

**Files:**
- Create: `project.godot`
- Create: `CLAUDE.md`
- Create: `src/autoload/game_events.gd`
- Create: `src/core/types.gd`

- [ ] **Step 1: Godot 프로젝트 생성**

```bash
cd /Users/jaejin/projects/toy/royal-puzzle-3
# Godot 4.4 프로젝트 생성 (headless)
godot --headless --quit --path . 2>/dev/null; or true
```

최소한의 `project.godot` 직접 작성:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be manually edited.

config_version=5

[application]
config/name="Royal Puzzle 3"
run/main_scene="res://scenes/game.tscn"
config/features=PackedStringArray("4.4")

[autoload]
GameEvents="*res://src/autoload/game_events.gd"
GameManager="*res://src/autoload/game_manager.gd"
SaveManager="*res://src/autoload/save_manager.gd"
AudioManager="*res://src/autoload/audio_manager.gd"

[display]
window/size/viewport_width=390
window/size/viewport_height=844
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_width"
window/handheld/orientation=1

[input]
touch={
"deadzone": 0.5,
"events": []
}

[rendering]
renderer/rendering_method="mobile"
textures/canvas_textures/default_texture_filter=0
```

- [ ] **Step 2: CLAUDE.md 작성**

```markdown
# Royal Puzzle 3

Godot 4.4 기반 Match-3 퍼즐 게임. "곰사원 회사 탈출" 테마.

## 빌드/실행
- `godot --headless --export-all` (빌드)
- Godot Editor에서 F5 (실행)

## 테스트
- GUT 프레임워크 사용
- Godot Editor > Run Tests 또는 `godot --headless -s addons/gut/gut_cmdln.gd`

## 구조
- `src/autoload/`: Godot 싱글톤 (이벤트, 상태, 저장, 오디오)
- `src/core/`: 순수 게임 로직 (씬 무관, 테스트 용이)
- `src/board/`: 보드 씬 & 렌더링
- `src/ui/`: UI 씬
- `src/effects/`: 파티클/이펙트
- `src/meta/`: 메타 루프 (방 꾸미기, 곰사원 Nightmare)
- `tests/`: GUT 테스트

## 컨벤션
- GDScript 스타일 가이드 준수 (snake_case)
- Signal로 시스템 간 통신 (직접 참조 최소화)
- 코어 로직은 Node 상속 없이 순수 GDScript 클래스
```

- [ ] **Step 3: types.gd 작성 (열거형/상수)**

```gdscript
# src/core/types.gd
class_name Types

enum GemType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }
enum BoosterType { H_ROCKET, V_ROCKET, TNT, LIGHT_BALL, MISSILE }
enum CellType { NORMAL, SPAWNER, BLANK, SHIFTER }
enum ObstacleType { NONE, STONE, FENCE, GRASS, CHAIN, GENERATOR, DOWNWARD }
enum MergeType {
    CROSS, BIG_ROCKET, MEGA_EXPLOSION, ALL_BOARD,
    COLOR_ROCKET, COLOR_TNT, COLOR_MISSILE,
    TRIPLE_MISSILE, MISSILE_ROCKET, MISSILE_TNT
}

const BOARD_COLS := 8
const BOARD_ROWS := 10
const CELL_SIZE := 44  # pixels
const GEM_TYPES_COUNT := 6
const MATCH_MIN := 3

# 보드 오프셋 (화면 중앙 정렬)
const BOARD_OFFSET_X := (390 - BOARD_COLS * CELL_SIZE) / 2
const BOARD_OFFSET_Y := 120  # HUD 아래
```

- [ ] **Step 4: game_events.gd 작성 (이벤트 버스)**

```gdscript
# src/autoload/game_events.gd
extends Node

# Board events
signal gems_matched(cells: Array, match_type: String)
signal gems_destroyed(cells: Array)
signal cascade_started()
signal cascade_ended()
signal board_settled()

# Booster events
signal booster_created(col: int, row: int, type: int)
signal booster_activated(col: int, row: int, type: int)
signal boosters_merged(col: int, row: int, merge_type: int)

# Game state events
signal moves_changed(remaining: int)
signal goal_progress(goal_type: String, current: int, target: int)
signal level_completed(stars: int)
signal level_failed()

# UI events
signal ui_booster_used(booster_type: String)
signal hint_requested()

# Meta events
signal star_earned(count: int)
signal task_completed(task_id: String)
signal area_completed(area_id: int)
signal room_decorated(room_id: int, item_id: String)
```

- [ ] **Step 5: git init & 커밋**

```bash
cd /Users/jaejin/projects/toy/royal-puzzle-3
git init
git add project.godot CLAUDE.md src/autoload/game_events.gd src/core/types.gd docs/
git commit -m "feat: Godot 4.4 프로젝트 초기화 + 타입 정의 + 이벤트 버스"
```

---

### Task 1.2: Match Detector (매치 감지 엔진)

**Files:**
- Create: `src/core/match_detector.gd`
- Create: `tests/test_match_detector.gd`

- [ ] **Step 1: 실패하는 테스트 작성**

```gdscript
# tests/test_match_detector.gd
extends GutTest

var detector: MatchDetector

func before_each():
    detector = MatchDetector.new()

func test_horizontal_match_3():
    # 8x10 보드, (2,3)-(3,3)-(4,3) 에 RED 배치
    var board = _create_empty_board()
    board[2][3] = Types.GemType.RED
    board[3][3] = Types.GemType.RED
    board[4][3] = Types.GemType.RED
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].cells.size(), 3)
    assert_eq(matches[0].type, "horizontal")

func test_vertical_match_3():
    var board = _create_empty_board()
    board[2][3] = Types.GemType.BLUE
    board[2][4] = Types.GemType.BLUE
    board[2][5] = Types.GemType.BLUE
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].type, "vertical")

func test_match_4_horizontal():
    var board = _create_empty_board()
    for i in range(4):
        board[2 + i][3] = Types.GemType.GREEN
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].cells.size(), 4)
    assert_eq(matches[0].type, "horizontal_4")

func test_match_5_creates_lightball():
    var board = _create_empty_board()
    for i in range(5):
        board[2 + i][3] = Types.GemType.YELLOW
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].cells.size(), 5)
    assert_eq(matches[0].type, "horizontal_5")

func test_l_shape_match():
    var board = _create_empty_board()
    # L자: (2,3)(3,3)(4,3) + (4,4)(4,5)
    board[2][3] = Types.GemType.RED
    board[3][3] = Types.GemType.RED
    board[4][3] = Types.GemType.RED
    board[4][4] = Types.GemType.RED
    board[4][5] = Types.GemType.RED
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].type, "l_shape")

func test_t_shape_match():
    var board = _create_empty_board()
    # T자: (2,3)(3,3)(4,3) + (3,2)(3,4)
    board[2][3] = Types.GemType.BLUE
    board[3][3] = Types.GemType.BLUE
    board[4][3] = Types.GemType.BLUE
    board[3][2] = Types.GemType.BLUE
    board[3][4] = Types.GemType.BLUE
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].type, "t_shape")

func test_no_match():
    var board = _create_empty_board()
    board[0][0] = Types.GemType.RED
    board[1][0] = Types.GemType.BLUE
    board[2][0] = Types.GemType.GREEN
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 0)

func test_cross_shape():
    var board = _create_empty_board()
    # +자: (3,2)(3,3)(3,4) + (2,3)(4,3)
    board[3][2] = Types.GemType.PURPLE
    board[3][3] = Types.GemType.PURPLE
    board[3][4] = Types.GemType.PURPLE
    board[2][3] = Types.GemType.PURPLE
    board[4][3] = Types.GemType.PURPLE
    var matches = detector.find_matches(board)
    assert_eq(matches.size(), 1)
    assert_eq(matches[0].type, "cross")

func _create_empty_board() -> Array:
    var board := []
    for col in range(Types.BOARD_COLS):
        var column := []
        for row in range(Types.BOARD_ROWS):
            column.append(-1)  # empty
        board.append(column)
    return board
```

- [ ] **Step 2: GUT 설치 확인 & 테스트 실패 확인**

```bash
# GUT이 없으면 AssetLib에서 다운로드 필요
# 테스트 실행
cd /Users/jaejin/projects/toy/royal-puzzle-3
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -ginclude_subdirs
```

Expected: FAIL - MatchDetector 클래스 미존재

- [ ] **Step 3: match_detector.gd 구현**

```gdscript
# src/core/match_detector.gd
class_name MatchDetector

class MatchResult:
    var cells: Array = []  # Array of Vector2i(col, row)
    var type: String = ""  # horizontal, vertical, horizontal_4, horizontal_5, l_shape, t_shape, cross
    var gem_type: int = -1

func find_matches(board: Array) -> Array:
    var h_runs := _find_horizontal_runs(board)
    var v_runs := _find_vertical_runs(board)
    var merged := _merge_intersecting(h_runs, v_runs)
    return _classify_matches(merged)

func _find_horizontal_runs(board: Array) -> Array:
    var runs := []
    var cols := board.size()
    if cols == 0:
        return runs
    var rows := board[0].size()
    for row in range(rows):
        var run_start := 0
        for col in range(1, cols + 1):
            var same := col < cols and board[col][row] == board[run_start][row] and board[col][row] >= 0
            if not same:
                if col - run_start >= Types.MATCH_MIN:
                    var cells := []
                    for c in range(run_start, col):
                        cells.append(Vector2i(c, row))
                    runs.append({"cells": cells, "gem_type": board[run_start][row], "dir": "h"})
                run_start = col
    return runs

func _find_vertical_runs(board: Array) -> Array:
    var runs := []
    var cols := board.size()
    if cols == 0:
        return runs
    var rows := board[0].size()
    for col in range(cols):
        var run_start := 0
        for row in range(1, rows + 1):
            var same := row < rows and board[col][row] == board[col][run_start] and board[col][row] >= 0
            if not same:
                if row - run_start >= Types.MATCH_MIN:
                    var cells := []
                    for r in range(run_start, row):
                        cells.append(Vector2i(col, r))
                    runs.append({"cells": cells, "gem_type": board[col][run_start], "dir": "v"})
                run_start = row
    return runs

func _merge_intersecting(h_runs: Array, v_runs: Array) -> Array:
    var groups := []
    var used_h := {}
    var used_v := {}

    for hi in range(h_runs.size()):
        for vi in range(v_runs.size()):
            if used_h.has(hi) or used_v.has(vi):
                continue
            if h_runs[hi].gem_type != v_runs[vi].gem_type:
                continue
            var h_set := {}
            for c in h_runs[hi].cells:
                h_set[c] = true
            var intersects := false
            for c in v_runs[vi].cells:
                if h_set.has(c):
                    intersects = true
                    break
            if intersects:
                var merged_cells := {}
                for c in h_runs[hi].cells:
                    merged_cells[c] = true
                for c in v_runs[vi].cells:
                    merged_cells[c] = true
                groups.append({"cells": merged_cells.keys(), "gem_type": h_runs[hi].gem_type, "h_count": h_runs[hi].cells.size(), "v_count": v_runs[vi].cells.size()})
                used_h[hi] = true
                used_v[vi] = true

    for hi in range(h_runs.size()):
        if not used_h.has(hi):
            groups.append({"cells": h_runs[hi].cells, "gem_type": h_runs[hi].gem_type, "h_count": h_runs[hi].cells.size(), "v_count": 0})
    for vi in range(v_runs.size()):
        if not used_v.has(vi):
            groups.append({"cells": v_runs[vi].cells, "gem_type": v_runs[vi].gem_type, "h_count": 0, "v_count": v_runs[vi].cells.size()})

    return groups

func _classify_matches(groups: Array) -> Array:
    var results := []
    for g in groups:
        var result := MatchResult.new()
        result.cells = g.cells
        result.gem_type = g.gem_type
        var total := result.cells.size()
        var h := g.h_count as int
        var v := g.v_count as int

        if h >= 3 and v >= 3:
            if h == 3 and v == 3:
                result.type = "cross"
            elif h > v:
                result.type = "t_shape"
            else:
                result.type = "t_shape"
        elif h > 0 and v > 0:
            result.type = "l_shape"
        elif h >= 5 or v >= 5:
            result.type = "horizontal_5" if h >= 5 else "vertical_5"
        elif h == 4 or v == 4:
            result.type = "horizontal_4" if h == 4 else "vertical_4"
        elif h == 3:
            result.type = "horizontal"
        elif v == 3:
            result.type = "vertical"
        else:
            result.type = "unknown"

        results.append(result)
    return results
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -ginclude_subdirs
```

Expected: 모든 match_detector 테스트 PASS

- [ ] **Step 5: 커밋**

```bash
git add src/core/match_detector.gd tests/test_match_detector.gd
git commit -m "feat: Match Detector 엔진 - 3/4/5/L/T/+ 매치 패턴 감지"
```

---

### Task 1.3: Gravity Handler (낙하 시스템)

**Files:**
- Create: `src/core/gravity_handler.gd`
- Create: `tests/test_gravity_handler.gd`

- [ ] **Step 1: 실패하는 테스트 작성**

```gdscript
# tests/test_gravity_handler.gd
extends GutTest

var handler: GravityHandler

func before_each():
    handler = GravityHandler.new()

func test_vertical_fall():
    # (2,3)이 빈칸이고 (2,2)에 보석 → (2,2)가 (2,3)으로 이동
    var board = _create_board_with_gap(2, 3)
    board[2][2] = Types.GemType.RED
    var moves = handler.calculate_falls(board)
    assert_true(moves.size() > 0)
    # (2,2) → (2,3) 이동 확인
    var found := false
    for m in moves:
        if m.from == Vector2i(2, 2) and m.to == Vector2i(2, 3):
            found = true
    assert_true(found, "보석이 아래로 낙하해야 함")

func test_diagonal_fall():
    # (2,3) 빈칸, (2,2)도 빈칸, (1,2)에 보석, (1,3)이 BLANK
    # → (1,2)가 대각선으로 (2,3)으로 이동
    var board = _create_empty_board()
    var cell_types = _create_cell_types()
    board[2][3] = -1  # empty
    board[2][2] = -1  # empty (위도 비어있음)
    board[1][2] = Types.GemType.BLUE
    cell_types[1][3] = Types.CellType.BLANK  # (1,3)은 블랭크
    var moves = handler.calculate_falls(board, cell_types)
    # 대각선 이동 존재 확인
    assert_true(moves.size() > 0)

func test_multiple_falls():
    # 한 열에서 연속 3칸 빈칸 → 위 3개 보석 순차 낙하
    var board = _create_empty_board()
    board[3][7] = -1  # empty
    board[3][8] = -1  # empty
    board[3][9] = -1  # empty
    board[3][4] = Types.GemType.RED
    board[3][5] = Types.GemType.BLUE
    board[3][6] = Types.GemType.GREEN
    var moves = handler.calculate_falls(board)
    assert_eq(moves.size(), 3)

func test_no_fall_when_full():
    var board = _create_full_board()
    var moves = handler.calculate_falls(board)
    assert_eq(moves.size(), 0)

func _create_empty_board() -> Array:
    var board := []
    for col in range(Types.BOARD_COLS):
        var column := []
        for row in range(Types.BOARD_ROWS):
            column.append(-1)
        board.append(column)
    return board

func _create_full_board() -> Array:
    var board := []
    for col in range(Types.BOARD_COLS):
        var column := []
        for row in range(Types.BOARD_ROWS):
            column.append(randi() % Types.GEM_TYPES_COUNT)
        board.append(column)
    return board

func _create_board_with_gap(col: int, row: int) -> Array:
    var board = _create_full_board()
    board[col][row] = -1
    return board

func _create_cell_types() -> Array:
    var types := []
    for col in range(Types.BOARD_COLS):
        var column := []
        for row in range(Types.BOARD_ROWS):
            column.append(Types.CellType.NORMAL)
        types.append(column)
    return types
```

- [ ] **Step 2: 테스트 실패 확인**

Expected: FAIL - GravityHandler 미존재

- [ ] **Step 3: gravity_handler.gd 구현**

```gdscript
# src/core/gravity_handler.gd
class_name GravityHandler

class FallMove:
    var from: Vector2i
    var to: Vector2i
    var gem_type: int

func calculate_falls(board: Array, cell_types: Array = []) -> Array:
    var moves := []
    var cols := board.size()
    if cols == 0:
        return moves
    var rows := board[0].size()

    # 각 열에서 아래부터 빈 칸 찾기 (수직 낙하)
    for col in range(cols):
        var write_row := rows - 1
        # 아래에서 위로 스캔, 빈칸 건너뛰기
        for read_row in range(rows - 1, -1, -1):
            if _is_blank_cell(col, read_row, cell_types):
                continue
            if board[col][read_row] >= 0:
                if read_row != write_row:
                    var move := FallMove.new()
                    move.from = Vector2i(col, read_row)
                    move.to = Vector2i(col, write_row)
                    move.gem_type = board[col][read_row]
                    moves.append(move)
                write_row -= 1
            elif board[col][read_row] == -1:
                pass  # 빈칸 → write_row 유지
            else:
                write_row = read_row - 1  # 장애물 등

    # 대각선 낙하 (빈칸 아래가 막혀있고 대각선이 비어있을 때)
    if cell_types.size() > 0:
        moves.append_array(_calculate_diagonal_falls(board, cell_types))

    return moves

func _calculate_diagonal_falls(board: Array, cell_types: Array) -> Array:
    var moves := []
    var cols := board.size()
    var rows := board[0].size()

    for col in range(cols):
        for row in range(rows - 1, 0, -1):
            if board[col][row] != -1:
                continue
            # 바로 위에 보석이 없고, 대각선에 보석이 있으면
            if board[col][row - 1] == -1 or board[col][row - 1] < 0:
                for dcol in [-1, 1]:
                    var ncol := col + dcol
                    if ncol < 0 or ncol >= cols:
                        continue
                    if row - 1 >= 0 and board[ncol][row - 1] >= 0:
                        # 대각선 위에 보석 있고, 그 보석의 바로 아래가 막혀있는 경우
                        if _is_blank_cell(ncol, row, cell_types) or (board[ncol][row] >= 0):
                            var move := FallMove.new()
                            move.from = Vector2i(ncol, row - 1)
                            move.to = Vector2i(col, row)
                            move.gem_type = board[ncol][row - 1]
                            moves.append(move)
                            break
    return moves

func _is_blank_cell(col: int, row: int, cell_types: Array) -> bool:
    if cell_types.size() == 0:
        return false
    if col < 0 or col >= cell_types.size():
        return false
    if row < 0 or row >= cell_types[col].size():
        return false
    return cell_types[col][row] == Types.CellType.BLANK
```

- [ ] **Step 4: 테스트 통과 확인**

- [ ] **Step 5: 커밋**

```bash
git add src/core/gravity_handler.gd tests/test_gravity_handler.gd
git commit -m "feat: Gravity Handler - 수직/대각선 낙하 시스템"
```

---

### Task 1.4: Board Logic (보드 코어 로직)

**Files:**
- Create: `src/core/board_logic.gd`
- Create: `tests/test_board_logic.gd`

- [ ] **Step 1: 실패하는 테스트 작성**

```gdscript
# tests/test_board_logic.gd
extends GutTest

var board: BoardLogic

func before_each():
    board = BoardLogic.new()
    board.initialize(Types.BOARD_COLS, Types.BOARD_ROWS)

func test_initialize_fills_board():
    assert_eq(board.cols, Types.BOARD_COLS)
    assert_eq(board.rows, Types.BOARD_ROWS)
    # 모든 셀에 유효한 보석이 있어야 함
    for col in range(board.cols):
        for row in range(board.rows):
            assert_true(board.get_gem(col, row) >= 0, "셀(%d,%d)에 보석이 있어야 함" % [col, row])

func test_initialize_no_initial_matches():
    # 초기 보드에 3매치가 없어야 함
    var matches = board.find_matches()
    assert_eq(matches.size(), 0, "초기 보드에 매치가 없어야 함")

func test_swap_gems():
    var gem_a = board.get_gem(0, 0)
    var gem_b = board.get_gem(1, 0)
    board.swap(Vector2i(0, 0), Vector2i(1, 0))
    assert_eq(board.get_gem(0, 0), gem_b)
    assert_eq(board.get_gem(1, 0), gem_a)

func test_swap_invalid_non_adjacent():
    var gem_a = board.get_gem(0, 0)
    var result = board.try_swap(Vector2i(0, 0), Vector2i(2, 0))
    assert_false(result, "인접하지 않은 스왑은 실패해야 함")

func test_remove_and_fill():
    # 수동으로 매치 생성 후 제거 → 낙하 → 리필
    board.set_gem(0, 7, Types.GemType.RED)
    board.set_gem(1, 7, Types.GemType.RED)
    board.set_gem(2, 7, Types.GemType.RED)
    var to_remove = [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)]
    board.remove_gems(to_remove)
    assert_eq(board.get_gem(0, 7), -1)
    board.apply_gravity()
    board.fill_empty()
    # 낙하 후 빈칸이 없어야 함
    for col in range(3):
        for row in range(board.rows):
            assert_true(board.get_gem(col, row) >= 0)

func test_cascade_loop():
    # process_turn: 매치 제거 → 낙하 → 리필 → 재매치 확인
    board.set_gem(0, 9, Types.GemType.RED)
    board.set_gem(1, 9, Types.GemType.RED)
    board.set_gem(2, 9, Types.GemType.RED)
    var result = board.process_matches()
    assert_true(result.matched, "매치가 처리되어야 함")
```

- [ ] **Step 2: 테스트 실패 확인**

- [ ] **Step 3: board_logic.gd 구현**

```gdscript
# src/core/board_logic.gd
class_name BoardLogic

var cols: int
var rows: int
var _grid: Array = []  # Array[Array[int]] - gem types (-1 = empty)
var _cell_types: Array = []  # Array[Array[CellType]]
var _match_detector: MatchDetector
var _gravity_handler: GravityHandler

class ProcessResult:
    var matched: bool = false
    var matches: Array = []
    var destroyed_cells: Array = []
    var cascade_count: int = 0

func initialize(p_cols: int, p_rows: int, cell_types: Array = []) -> void:
    cols = p_cols
    rows = p_rows
    _match_detector = MatchDetector.new()
    _gravity_handler = GravityHandler.new()
    _cell_types = cell_types if cell_types.size() > 0 else _default_cell_types()
    _grid = _generate_no_match_board()

func get_gem(col: int, row: int) -> int:
    if col < 0 or col >= cols or row < 0 or row >= rows:
        return -1
    return _grid[col][row]

func set_gem(col: int, row: int, gem_type: int) -> void:
    if col >= 0 and col < cols and row >= 0 and row < rows:
        _grid[col][row] = gem_type

func try_swap(from: Vector2i, to: Vector2i) -> bool:
    if abs(from.x - to.x) + abs(from.y - to.y) != 1:
        return false
    if get_gem(from.x, from.y) < 0 or get_gem(to.x, to.y) < 0:
        return false
    return true

func swap(from: Vector2i, to: Vector2i) -> void:
    var temp := _grid[from.x][from.y]
    _grid[from.x][from.y] = _grid[to.x][to.y]
    _grid[to.x][to.y] = temp

func find_matches() -> Array:
    return _match_detector.find_matches(_grid)

func remove_gems(cells: Array) -> void:
    for cell in cells:
        _grid[cell.x][cell.y] = -1

func apply_gravity() -> Array:
    var moves := _gravity_handler.calculate_falls(_grid, _cell_types)
    for m in moves:
        _grid[m.to.x][m.to.y] = m.gem_type
        _grid[m.from.x][m.from.y] = -1
    return moves

func fill_empty() -> Array:
    var filled := []
    for col in range(cols):
        for row in range(rows):
            if _grid[col][row] == -1 and _cell_types[col][row] != Types.CellType.BLANK:
                _grid[col][row] = _random_gem_avoiding_match(col, row)
                filled.append(Vector2i(col, row))
    return filled

func process_matches() -> ProcessResult:
    var result := ProcessResult.new()
    var matches := find_matches()
    if matches.size() == 0:
        return result
    result.matched = true
    result.matches = matches
    for m in matches:
        for cell in m.cells:
            if not result.destroyed_cells.has(cell):
                result.destroyed_cells.append(cell)
    remove_gems(result.destroyed_cells)
    return result

func process_cascade() -> int:
    var cascade_count := 0
    while true:
        var result := process_matches()
        if not result.matched:
            break
        cascade_count += 1
        apply_gravity()
        fill_empty()
    return cascade_count

func _generate_no_match_board() -> Array:
    var grid := []
    for col in range(cols):
        var column := []
        for row in range(rows):
            column.append(_random_gem_avoiding_match_in(grid, column, col, row))
        grid.append(column)
    return grid

func _random_gem_avoiding_match_in(grid: Array, current_col: Array, col: int, row: int) -> int:
    var max_attempts := 20
    for _i in range(max_attempts):
        var gem := randi() % Types.GEM_TYPES_COUNT
        # 가로 체크
        if col >= 2:
            if grid[col - 1][row] == gem and grid[col - 2][row] == gem:
                continue
        # 세로 체크
        if row >= 2:
            if current_col[row - 1] == gem and current_col[row - 2] == gem:
                continue
        return gem
    return randi() % Types.GEM_TYPES_COUNT

func _random_gem_avoiding_match(col: int, row: int) -> int:
    var max_attempts := 20
    for _i in range(max_attempts):
        var gem := randi() % Types.GEM_TYPES_COUNT
        if col >= 2 and _grid[col - 1][row] == gem and _grid[col - 2][row] == gem:
            continue
        if row >= 2 and _grid[col][row - 1] == gem and _grid[col][row - 2] == gem:
            continue
        return gem
    return randi() % Types.GEM_TYPES_COUNT

func _default_cell_types() -> Array:
    var types := []
    for col in range(cols):
        var column := []
        for row in range(rows):
            column.append(Types.CellType.NORMAL)
        types.append(column)
    return types
```

- [ ] **Step 4: 테스트 통과 확인**

- [ ] **Step 5: 커밋**

```bash
git add src/core/board_logic.gd tests/test_board_logic.gd
git commit -m "feat: Board Logic - 초기화/스왑/매치처리/낙하/리필/캐스케이드"
```

---

### Task 1.5: Board Scene & Renderer (보드 씬 + 시각화)

**Files:**
- Create: `src/board/board.tscn`
- Create: `src/board/board.gd`
- Create: `src/board/gem.tscn`
- Create: `src/board/gem.gd`
- Create: `src/board/cell.tscn`
- Create: `src/board/cell.gd`

- [ ] **Step 1: gem.tscn/gem.gd 생성 (보석 노드)**

```gdscript
# src/board/gem.gd
extends Sprite2D

var gem_type: int = -1
var grid_pos: Vector2i = Vector2i.ZERO
var _target_position: Vector2
var _is_moving: bool = false

const FALL_SPEED := 800.0
const SWAP_SPEED := 400.0

# 플레이스홀더 색상 (에셋 로드 전)
const GEM_COLORS := [
    Color.RED, Color.BLUE, Color.GREEN,
    Color.YELLOW, Color.PURPLE, Color.ORANGE
]

func setup(type: int, col: int, row: int) -> void:
    gem_type = type
    grid_pos = Vector2i(col, row)
    position = _grid_to_world(col, row)
    _target_position = position
    modulate = GEM_COLORS[type] if type >= 0 and type < GEM_COLORS.size() else Color.WHITE

func move_to(col: int, row: int, speed: float = FALL_SPEED) -> void:
    grid_pos = Vector2i(col, row)
    _target_position = _grid_to_world(col, row)
    _is_moving = true

func _process(delta: float) -> void:
    if _is_moving:
        position = position.move_toward(_target_position, FALL_SPEED * delta)
        if position.distance_to(_target_position) < 1.0:
            position = _target_position
            _is_moving = false

func destroy() -> void:
    # 파괴 애니메이션 후 제거
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
    tween.tween_callback(queue_free)

func _grid_to_world(col: int, row: int) -> Vector2:
    return Vector2(
        Types.BOARD_OFFSET_X + col * Types.CELL_SIZE + Types.CELL_SIZE / 2,
        Types.BOARD_OFFSET_Y + row * Types.CELL_SIZE + Types.CELL_SIZE / 2
    )
```

- [ ] **Step 2: board.gd 생성 (보드 컨트롤러)**

```gdscript
# src/board/board.gd
extends Node2D

var _logic: BoardLogic
var _gem_nodes: Dictionary = {}  # Vector2i → Gem node
var _is_processing: bool = false

@onready var _gem_container := $GemContainer

func _ready() -> void:
    _logic = BoardLogic.new()
    _logic.initialize(Types.BOARD_COLS, Types.BOARD_ROWS)
    _create_gem_nodes()

func _create_gem_nodes() -> void:
    for col in range(_logic.cols):
        for row in range(_logic.rows):
            var gem_type := _logic.get_gem(col, row)
            if gem_type >= 0:
                _spawn_gem(col, row, gem_type)

func _spawn_gem(col: int, row: int, gem_type: int) -> void:
    var gem := preload("res://src/board/gem.tscn").instantiate()
    gem.setup(gem_type, col, row)
    _gem_container.add_child(gem)
    _gem_nodes[Vector2i(col, row)] = gem

func try_swap(from: Vector2i, to: Vector2i) -> void:
    if _is_processing:
        return
    if not _logic.try_swap(from, to):
        return

    _is_processing = true
    _logic.swap(from, to)

    # 스왑 애니메이션
    var gem_a: Sprite2D = _gem_nodes.get(from)
    var gem_b: Sprite2D = _gem_nodes.get(to)
    if gem_a:
        gem_a.move_to(to.x, to.y, gem_a.SWAP_SPEED)
    if gem_b:
        gem_b.move_to(from.x, from.y, gem_b.SWAP_SPEED)
    _gem_nodes[from] = gem_b
    _gem_nodes[to] = gem_a

    # 매치 확인
    await get_tree().create_timer(0.2).timeout
    var result := _logic.process_matches()

    if not result.matched:
        # 스왑 취소
        _logic.swap(from, to)
        if gem_a:
            gem_a.move_to(from.x, from.y, gem_a.SWAP_SPEED)
        if gem_b:
            gem_b.move_to(to.x, to.y, gem_b.SWAP_SPEED)
        _gem_nodes[from] = gem_a
        _gem_nodes[to] = gem_b
        await get_tree().create_timer(0.2).timeout
        _is_processing = false
        return

    # 매치된 보석 파괴
    _destroy_matched(result.destroyed_cells)
    GameEvents.gems_matched.emit(result.destroyed_cells, result.matches[0].type if result.matches.size() > 0 else "")
    GameEvents.moves_changed.emit(-1)

    await get_tree().create_timer(0.2).timeout

    # 캐스케이드 루프
    _run_cascade()

func _destroy_matched(cells: Array) -> void:
    for cell in cells:
        var gem = _gem_nodes.get(cell)
        if gem:
            gem.destroy()
            _gem_nodes.erase(cell)
    GameEvents.gems_destroyed.emit(cells)

func _run_cascade() -> void:
    while true:
        var falls := _logic.apply_gravity()
        _animate_falls(falls)
        await get_tree().create_timer(0.15).timeout

        var filled := _logic.fill_empty()
        _spawn_new_gems(filled)
        await get_tree().create_timer(0.15).timeout

        var result := _logic.process_matches()
        if not result.matched:
            break
        _destroy_matched(result.destroyed_cells)
        GameEvents.cascade_started.emit()
        await get_tree().create_timer(0.2).timeout

    GameEvents.board_settled.emit()
    _is_processing = false

func _animate_falls(falls: Array) -> void:
    for fall in falls:
        var gem = _gem_nodes.get(fall.from)
        if gem:
            _gem_nodes.erase(fall.from)
            gem.move_to(fall.to.x, fall.to.y)
            _gem_nodes[fall.to] = gem

func _spawn_new_gems(positions: Array) -> void:
    for pos in positions:
        var gem_type := _logic.get_gem(pos.x, pos.y)
        _spawn_gem(pos.x, pos.y, gem_type)
```

- [ ] **Step 3: Input Handler 추가**

```gdscript
# src/board/input_handler.gd
extends Node2D

signal swap_requested(from: Vector2i, to: Vector2i)

var _touch_start: Vector2 = Vector2.ZERO
var _is_touching: bool = false
var _start_cell: Vector2i = Vector2i(-1, -1)
const SWIPE_THRESHOLD := 20.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_start = event.position
            _is_touching = true
            _start_cell = _world_to_grid(event.position)
        else:
            _is_touching = false
    elif event is InputEventScreenDrag and _is_touching:
        var delta := event.position - _touch_start
        if delta.length() > SWIPE_THRESHOLD:
            var direction := _snap_direction(delta)
            var target := _start_cell + direction
            if _start_cell.x >= 0:
                swap_requested.emit(_start_cell, target)
            _is_touching = false
    # 마우스 폴백 (데스크탑 테스트용)
    elif event is InputEventMouseButton:
        if event.pressed:
            _touch_start = event.position
            _is_touching = true
            _start_cell = _world_to_grid(event.position)
        else:
            _is_touching = false
    elif event is InputEventMouseMotion and _is_touching:
        var delta := event.position - _touch_start
        if delta.length() > SWIPE_THRESHOLD:
            var direction := _snap_direction(delta)
            var target := _start_cell + direction
            if _start_cell.x >= 0:
                swap_requested.emit(_start_cell, target)
            _is_touching = false

func _snap_direction(delta: Vector2) -> Vector2i:
    if abs(delta.x) > abs(delta.y):
        return Vector2i(1, 0) if delta.x > 0 else Vector2i(-1, 0)
    else:
        return Vector2i(0, 1) if delta.y > 0 else Vector2i(0, -1)

func _world_to_grid(world_pos: Vector2) -> Vector2i:
    var col := int((world_pos.x - Types.BOARD_OFFSET_X) / Types.CELL_SIZE)
    var row := int((world_pos.y - Types.BOARD_OFFSET_Y) / Types.CELL_SIZE)
    if col < 0 or col >= Types.BOARD_COLS or row < 0 or row >= Types.BOARD_ROWS:
        return Vector2i(-1, -1)
    return Vector2i(col, row)
```

- [ ] **Step 4: Game Scene 연결**

```gdscript
# scenes/game.gd
extends Node2D

@onready var _board: Node2D = $Board
@onready var _input: Node2D = $InputHandler

func _ready() -> void:
    _input.swap_requested.connect(_on_swap_requested)

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
    _board.try_swap(from, to)
```

game.tscn 구조:
```
Game (Node2D)
├── Board (board.tscn)
│   └── GemContainer (Node2D)
└── InputHandler (input_handler.gd)
```

- [ ] **Step 5: 플레이 테스트**

Godot Editor에서 F5로 실행:
- 8x10 보드에 6색 보석이 표시되는지 확인
- 스와이프로 교환되는지 확인
- 3매치 시 파괴 → 낙하 → 리필이 동작하는지 확인
- 잘못된 스왑(매치 안됨)이 되돌려지는지 확인

- [ ] **Step 6: 커밋**

```bash
git add src/board/ scenes/
git commit -m "feat: 보드 씬 + 보석 렌더링 + 스와이프 입력 + 게임 루프 연결"
```

---

### Task 1.6: Game Manager & Level State

**Files:**
- Create: `src/autoload/game_manager.gd`
- Create: `src/data/level_data.gd`

- [ ] **Step 1: game_manager.gd 작성**

```gdscript
# src/autoload/game_manager.gd
extends Node

var current_level: int = 1
var remaining_moves: int = 20
var goals: Dictionary = {}  # {"gem_type": {"current": 0, "target": 12}}
var is_level_active: bool = false

func start_level(level_id: int, level_data: LevelData) -> void:
    current_level = level_id
    remaining_moves = level_data.moves
    goals.clear()
    for goal in level_data.goals:
        goals[goal.type] = {"current": 0, "target": goal.amount}
    is_level_active = true

func use_move() -> void:
    remaining_moves -= 1
    GameEvents.moves_changed.emit(remaining_moves)
    if remaining_moves <= 0 and not _all_goals_met():
        is_level_active = false
        GameEvents.level_failed.emit()

func add_goal_progress(goal_type: String, amount: int = 1) -> void:
    if goals.has(goal_type):
        goals[goal_type].current += amount
        var g = goals[goal_type]
        GameEvents.goal_progress.emit(goal_type, g.current, g.target)
        if _all_goals_met():
            _complete_level()

func _all_goals_met() -> bool:
    for key in goals:
        if goals[key].current < goals[key].target:
            return false
    return true

func _complete_level() -> void:
    is_level_active = false
    var stars := _calculate_stars()
    GameEvents.level_completed.emit(stars)
    GameEvents.star_earned.emit(stars)

func _calculate_stars() -> int:
    if remaining_moves >= 10:
        return 3
    elif remaining_moves >= 5:
        return 2
    else:
        return 1
```

- [ ] **Step 2: level_data.gd 작성**

```gdscript
# src/data/level_data.gd
class_name LevelData
extends Resource

class Goal:
    var type: String  # "red", "blue", "obstacle_box", etc.
    var amount: int

@export var level_id: int
@export var moves: int = 20
@export var board_cols: int = 8
@export var board_rows: int = 10
@export var goals_data: Array = []  # [{"type": "red", "amount": 12}]
@export var cell_layout: Array = []  # 비정형 보드용
@export var obstacles: Array = []  # [{"col": 2, "row": 3, "type": "stone"}]
@export var available_gems: Array = [0, 1, 2, 3, 4]  # 사용 가능한 보석 타입

var goals: Array:
    get:
        var result := []
        for gd in goals_data:
            var g := Goal.new()
            g.type = gd.get("type", "")
            g.amount = gd.get("amount", 0)
            result.append(g)
        return result
```

- [ ] **Step 3: 커밋**

```bash
git add src/autoload/game_manager.gd src/data/level_data.gd
git commit -m "feat: Game Manager + Level Data - 이동수/목표/별점 관리"
```

---

## Chunk 2: Boosters & Obstacles

**목표**: 5종 인게임 부스터 + 10종 합체 조합 + 6종 장애물(3레이어) 동작

---

### Task 2.1: Booster Rules (부스터 생성 규칙)

**Files:**
- Create: `src/core/booster_rules.gd`
- Create: `tests/test_booster_rules.gd`

- [ ] **Step 1: 실패하는 테스트**

```gdscript
# tests/test_booster_rules.gd
extends GutTest

var rules: BoosterRules

func before_each():
    rules = BoosterRules.new()

func test_match_3_no_booster():
    var match_type := "horizontal"
    var result = rules.get_booster_for_match(match_type, 3)
    assert_eq(result, Types.BoosterType.H_ROCKET - Types.BoosterType.H_ROCKET)  # -1 = no booster
    # Actually:
    assert_eq(result, -1)

func test_horizontal_4_creates_v_rocket():
    # 가로 4매치 → 세로 로켓 (Gem-Match3 규칙: 반대 방향)
    assert_eq(rules.get_booster_for_match("horizontal_4", 4), Types.BoosterType.V_ROCKET)

func test_vertical_4_creates_h_rocket():
    assert_eq(rules.get_booster_for_match("vertical_4", 4), Types.BoosterType.H_ROCKET)

func test_5_match_creates_lightball():
    assert_eq(rules.get_booster_for_match("horizontal_5", 5), Types.BoosterType.LIGHT_BALL)
    assert_eq(rules.get_booster_for_match("vertical_5", 5), Types.BoosterType.LIGHT_BALL)

func test_l_shape_creates_tnt():
    assert_eq(rules.get_booster_for_match("l_shape", 5), Types.BoosterType.TNT)

func test_t_shape_creates_tnt():
    assert_eq(rules.get_booster_for_match("t_shape", 5), Types.BoosterType.TNT)

func test_cross_creates_tnt():
    assert_eq(rules.get_booster_for_match("cross", 5), Types.BoosterType.TNT)
```

- [ ] **Step 2: booster_rules.gd 구현**

```gdscript
# src/core/booster_rules.gd
class_name BoosterRules

## 매치 타입에 따른 부스터 생성 규칙
## Royal Match/Gem-Match3 규칙: 4매치 로켓은 매치 방향의 반대
func get_booster_for_match(match_type: String, cell_count: int) -> int:
    match match_type:
        "horizontal_4":
            return Types.BoosterType.V_ROCKET
        "vertical_4":
            return Types.BoosterType.H_ROCKET
        "horizontal_5", "vertical_5":
            return Types.BoosterType.LIGHT_BALL
        "l_shape", "t_shape", "cross":
            return Types.BoosterType.TNT
        _:
            if cell_count >= 5:
                return Types.BoosterType.LIGHT_BALL
            return -1  # no booster
```

- [ ] **Step 3: 테스트 통과 확인 & 커밋**

```bash
git add src/core/booster_rules.gd tests/test_booster_rules.gd
git commit -m "feat: Booster Rules - 매치 패턴별 부스터 생성 (4→로켓, 5→라이트볼, L/T/+→TNT)"
```

---

### Task 2.2: Booster Executor (부스터 실행)

**Files:**
- Create: `src/core/booster_executor.gd`
- Create: `tests/test_booster_executor.gd`

- [ ] **Step 1: 실패하는 테스트**

```gdscript
# tests/test_booster_executor.gd
extends GutTest

var executor: BoosterExecutor

func before_each():
    executor = BoosterExecutor.new()

func test_h_rocket_destroys_row():
    var targets = executor.get_targets(Types.BoosterType.H_ROCKET, 3, 5, 8, 10)
    # 같은 행(5)의 모든 열 포함
    for col in range(8):
        assert_true(Vector2i(col, 5) in targets)
    assert_eq(targets.size(), 8)

func test_v_rocket_destroys_col():
    var targets = executor.get_targets(Types.BoosterType.V_ROCKET, 3, 5, 8, 10)
    for row in range(10):
        assert_true(Vector2i(3, row) in targets)
    assert_eq(targets.size(), 10)

func test_tnt_radius_2():
    var targets = executor.get_targets(Types.BoosterType.TNT, 4, 5, 8, 10)
    # 반경 2 내의 모든 유효 셀
    for dc in range(-2, 3):
        for dr in range(-2, 3):
            var c := 4 + dc
            var r := 5 + dr
            if c >= 0 and c < 8 and r >= 0 and r < 10:
                assert_true(Vector2i(c, r) in targets)

func test_lightball_finds_most_common():
    var board := []
    for col in range(8):
        var column := []
        for row in range(10):
            column.append(Types.GemType.RED if col < 5 else Types.GemType.BLUE)
        board.append(column)
    var targets = executor.get_lightball_targets(board, Types.GemType.RED)
    # RED가 더 많으므로 모든 RED 위치 반환
    assert_true(targets.size() > 0)
    for t in targets:
        assert_eq(board[t.x][t.y], Types.GemType.RED)
```

- [ ] **Step 2: booster_executor.gd 구현**

```gdscript
# src/core/booster_executor.gd
class_name BoosterExecutor

func get_targets(booster_type: int, col: int, row: int, board_cols: int, board_rows: int) -> Array:
    match booster_type:
        Types.BoosterType.H_ROCKET:
            return _get_row_targets(row, board_cols)
        Types.BoosterType.V_ROCKET:
            return _get_col_targets(col, board_rows)
        Types.BoosterType.TNT:
            return _get_tnt_targets(col, row, 2, board_cols, board_rows)
        Types.BoosterType.MISSILE:
            return []  # 미사일은 별도 처리 (골 위치 참조)
        _:
            return []

func get_lightball_targets(board: Array, swap_gem_type: int) -> Array:
    # LightBall: 스왑한 보석 색상 전체 제거
    var targets := []
    for col in range(board.size()):
        for row in range(board[col].size()):
            if board[col][row] == swap_gem_type:
                targets.append(Vector2i(col, row))
    return targets

func _get_row_targets(row: int, cols: int) -> Array:
    var targets := []
    for col in range(cols):
        targets.append(Vector2i(col, row))
    return targets

func _get_col_targets(col: int, rows: int) -> Array:
    var targets := []
    for row in range(rows):
        targets.append(Vector2i(col, row))
    return targets

func _get_tnt_targets(center_col: int, center_row: int, radius: int, cols: int, rows: int) -> Array:
    var targets := []
    for dc in range(-radius, radius + 1):
        for dr in range(-radius, radius + 1):
            var c := center_col + dc
            var r := center_row + dr
            if c >= 0 and c < cols and r >= 0 and r < rows:
                targets.append(Vector2i(c, r))
    return targets
```

- [ ] **Step 3: 테스트 통과 & 커밋**

```bash
git add src/core/booster_executor.gd tests/test_booster_executor.gd
git commit -m "feat: Booster Executor - H/V Rocket, TNT(반경2), LightBall 타겟 계산"
```

---

### Task 2.3: Booster Merger (부스터 합체 10종)

**Files:**
- Create: `src/core/booster_merger.gd`
- Create: `tests/test_booster_merger.gd`

- [ ] **Step 1: 실패하는 테스트**

```gdscript
# tests/test_booster_merger.gd
extends GutTest

var merger: BoosterMerger

func before_each():
    merger = BoosterMerger.new()

func test_rocket_rocket_cross():
    var result = merger.get_merge_type(Types.BoosterType.H_ROCKET, Types.BoosterType.V_ROCKET)
    assert_eq(result, Types.MergeType.CROSS)

func test_tnt_tnt_mega():
    var result = merger.get_merge_type(Types.BoosterType.TNT, Types.BoosterType.TNT)
    assert_eq(result, Types.MergeType.MEGA_EXPLOSION)

func test_lightball_lightball_all():
    var result = merger.get_merge_type(Types.BoosterType.LIGHT_BALL, Types.BoosterType.LIGHT_BALL)
    assert_eq(result, Types.MergeType.ALL_BOARD)

func test_lightball_rocket_color_rocket():
    var result = merger.get_merge_type(Types.BoosterType.LIGHT_BALL, Types.BoosterType.H_ROCKET)
    assert_eq(result, Types.MergeType.COLOR_ROCKET)

func test_lightball_tnt_color_tnt():
    var result = merger.get_merge_type(Types.BoosterType.LIGHT_BALL, Types.BoosterType.TNT)
    assert_eq(result, Types.MergeType.COLOR_TNT)

func test_tnt_rocket_big_rocket():
    var result = merger.get_merge_type(Types.BoosterType.TNT, Types.BoosterType.H_ROCKET)
    assert_eq(result, Types.MergeType.BIG_ROCKET)

func test_normal_gem_no_merge():
    var result = merger.get_merge_type(-1, Types.BoosterType.TNT)
    assert_eq(result, -1)

func test_commutative():
    # A+B == B+A
    var ab = merger.get_merge_type(Types.BoosterType.H_ROCKET, Types.BoosterType.TNT)
    var ba = merger.get_merge_type(Types.BoosterType.TNT, Types.BoosterType.H_ROCKET)
    assert_eq(ab, ba)
```

- [ ] **Step 2: booster_merger.gd 구현**

```gdscript
# src/core/booster_merger.gd
class_name BoosterMerger

# 합체 룩업 테이블 (대칭)
var _merge_table: Dictionary = {}

func _init():
    _register(Types.BoosterType.H_ROCKET, Types.BoosterType.V_ROCKET, Types.MergeType.CROSS)
    _register(Types.BoosterType.H_ROCKET, Types.BoosterType.H_ROCKET, Types.MergeType.CROSS)
    _register(Types.BoosterType.V_ROCKET, Types.BoosterType.V_ROCKET, Types.MergeType.CROSS)
    _register(Types.BoosterType.TNT, Types.BoosterType.H_ROCKET, Types.MergeType.BIG_ROCKET)
    _register(Types.BoosterType.TNT, Types.BoosterType.V_ROCKET, Types.MergeType.BIG_ROCKET)
    _register(Types.BoosterType.TNT, Types.BoosterType.TNT, Types.MergeType.MEGA_EXPLOSION)
    _register(Types.BoosterType.LIGHT_BALL, Types.BoosterType.LIGHT_BALL, Types.MergeType.ALL_BOARD)
    _register(Types.BoosterType.LIGHT_BALL, Types.BoosterType.H_ROCKET, Types.MergeType.COLOR_ROCKET)
    _register(Types.BoosterType.LIGHT_BALL, Types.BoosterType.V_ROCKET, Types.MergeType.COLOR_ROCKET)
    _register(Types.BoosterType.LIGHT_BALL, Types.BoosterType.TNT, Types.MergeType.COLOR_TNT)
    _register(Types.BoosterType.LIGHT_BALL, Types.BoosterType.MISSILE, Types.MergeType.COLOR_MISSILE)
    _register(Types.BoosterType.MISSILE, Types.BoosterType.MISSILE, Types.MergeType.TRIPLE_MISSILE)
    _register(Types.BoosterType.MISSILE, Types.BoosterType.H_ROCKET, Types.MergeType.MISSILE_ROCKET)
    _register(Types.BoosterType.MISSILE, Types.BoosterType.V_ROCKET, Types.MergeType.MISSILE_ROCKET)
    _register(Types.BoosterType.MISSILE, Types.BoosterType.TNT, Types.MergeType.MISSILE_TNT)

func get_merge_type(type_a: int, type_b: int) -> int:
    if type_a < 0 or type_b < 0:
        return -1
    var key := _make_key(type_a, type_b)
    return _merge_table.get(key, -1)

func _register(a: int, b: int, merge: int) -> void:
    _merge_table[_make_key(a, b)] = merge

func _make_key(a: int, b: int) -> int:
    # 대칭 키: min * 100 + max
    return min(a, b) * 100 + max(a, b)
```

- [ ] **Step 3: 테스트 통과 & 커밋**

```bash
git add src/core/booster_merger.gd tests/test_booster_merger.gd
git commit -m "feat: Booster Merger - 10종 합체 조합 룩업 테이블"
```

---

### Task 2.4: Obstacle Manager (3레이어 장애물)

**Files:**
- Create: `src/core/obstacle_manager.gd`
- Create: `tests/test_obstacle_manager.gd`

- [ ] **Step 1: 실패하는 테스트**

```gdscript
# tests/test_obstacle_manager.gd
extends GutTest

var manager: ObstacleManager

func before_each():
    manager = ObstacleManager.new()
    manager.initialize(8, 10)

func test_stone_blocks_swap():
    manager.set_obstacle(3, 5, Types.ObstacleType.STONE, "main")
    assert_false(manager.can_swap(3, 5))

func test_stone_damaged_by_adjacent_match():
    manager.set_obstacle(3, 5, Types.ObstacleType.STONE, "main", 1)
    var damaged = manager.process_adjacent_match([Vector2i(2, 5), Vector2i(4, 5)])
    assert_true(Vector2i(3, 5) in damaged)

func test_fence_protects_gem():
    manager.set_obstacle(3, 5, Types.ObstacleType.FENCE, "overlay")
    assert_true(manager.has_overlay(3, 5))
    assert_false(manager.can_match(3, 5))

func test_fence_broken_by_adjacent():
    manager.set_obstacle(3, 5, Types.ObstacleType.FENCE, "overlay", 1)
    manager.damage_overlay(3, 5)
    assert_false(manager.has_overlay(3, 5))

func test_grass_cleared_on_match():
    manager.set_obstacle(3, 5, Types.ObstacleType.GRASS, "underlay")
    assert_true(manager.has_underlay(3, 5))
    manager.clear_underlay(3, 5)
    assert_false(manager.has_underlay(3, 5))

func test_chain_prevents_movement():
    manager.set_obstacle(3, 5, Types.ObstacleType.CHAIN, "overlay")
    assert_false(manager.can_swap(3, 5))
    assert_true(manager.can_match(3, 5))  # 매칭은 가능

func test_multi_hp_obstacle():
    manager.set_obstacle(3, 5, Types.ObstacleType.STONE, "main", 3)
    manager.damage_main(3, 5)
    assert_true(manager.has_main(3, 5))  # HP 2 남음
    manager.damage_main(3, 5)
    assert_true(manager.has_main(3, 5))  # HP 1 남음
    manager.damage_main(3, 5)
    assert_false(manager.has_main(3, 5))  # 파괴됨
```

- [ ] **Step 2: obstacle_manager.gd 구현**

```gdscript
# src/core/obstacle_manager.gd
class_name ObstacleManager

class CellObstacle:
    var type: int = Types.ObstacleType.NONE
    var hp: int = 0
    var layer: String = ""  # "main", "overlay", "underlay"

var _main: Array = []      # 메인 레이어 (Stone, Generator, Downward)
var _overlay: Array = []   # 오버레이 (Fence, Chain)
var _underlay: Array = []  # 언더레이 (Grass)
var _cols: int
var _rows: int

func initialize(cols: int, rows: int) -> void:
    _cols = cols
    _rows = rows
    _main = _create_layer(cols, rows)
    _overlay = _create_layer(cols, rows)
    _underlay = _create_layer(cols, rows)

func set_obstacle(col: int, row: int, type: int, layer: String, hp: int = 1) -> void:
    var obs := CellObstacle.new()
    obs.type = type
    obs.hp = hp
    obs.layer = layer
    match layer:
        "main": _main[col][row] = obs
        "overlay": _overlay[col][row] = obs
        "underlay": _underlay[col][row] = obs

func can_swap(col: int, row: int) -> bool:
    if _has_obstacle(_main, col, row) and _main[col][row].type == Types.ObstacleType.STONE:
        return false
    if _has_obstacle(_overlay, col, row) and _overlay[col][row].type == Types.ObstacleType.CHAIN:
        return false
    return true

func can_match(col: int, row: int) -> bool:
    if _has_obstacle(_main, col, row):
        return false
    if _has_obstacle(_overlay, col, row) and _overlay[col][row].type == Types.ObstacleType.FENCE:
        return false
    return true

func has_main(col: int, row: int) -> bool:
    return _has_obstacle(_main, col, row)

func has_overlay(col: int, row: int) -> bool:
    return _has_obstacle(_overlay, col, row)

func has_underlay(col: int, row: int) -> bool:
    return _has_obstacle(_underlay, col, row)

func damage_main(col: int, row: int) -> void:
    _damage(_main, col, row)

func damage_overlay(col: int, row: int) -> void:
    _damage(_overlay, col, row)

func clear_underlay(col: int, row: int) -> void:
    if _has_obstacle(_underlay, col, row):
        _underlay[col][row] = null

func process_adjacent_match(matched_cells: Array) -> Array:
    var damaged := []
    for cell in matched_cells:
        for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
            var nc := cell.x + dir.x
            var nr := cell.y + dir.y
            if nc >= 0 and nc < _cols and nr >= 0 and nr < _rows:
                if _has_obstacle(_main, nc, nr):
                    _damage(_main, nc, nr)
                    damaged.append(Vector2i(nc, nr))
                if _has_obstacle(_overlay, nc, nr):
                    _damage(_overlay, nc, nr)
                    damaged.append(Vector2i(nc, nr))
    return damaged

func _damage(layer: Array, col: int, row: int) -> void:
    if layer[col][row] != null and layer[col][row] is CellObstacle:
        layer[col][row].hp -= 1
        if layer[col][row].hp <= 0:
            layer[col][row] = null

func _has_obstacle(layer: Array, col: int, row: int) -> bool:
    return layer[col][row] != null and layer[col][row] is CellObstacle

func _create_layer(cols: int, rows: int) -> Array:
    var layer := []
    for col in range(cols):
        var column := []
        for row in range(rows):
            column.append(null)
        layer.append(column)
    return layer
```

- [ ] **Step 3: 테스트 통과 & 커밋**

```bash
git add src/core/obstacle_manager.gd tests/test_obstacle_manager.gd
git commit -m "feat: Obstacle Manager - 3레이어(main/overlay/underlay) + Stone/Fence/Grass/Chain + HP"
```

---

## Chunk 3: Level System & Progression

**목표**: 200레벨 자동 생성 + 에리어/별 시스템 + 저장/로드

---

### Task 3.1: Level Generator (200레벨 자동 생성)

**Files:**
- Create: `src/core/level_generator.gd`
- Create: `tests/test_level_generator.gd`

- [ ] **Step 1: 실패하는 테스트**

```gdscript
# tests/test_level_generator.gd
extends GutTest

var gen: LevelGenerator

func before_each():
    gen = LevelGenerator.new()

func test_level_1_is_easy():
    var level = gen.generate(1)
    assert_gte(level.moves, 18)
    assert_eq(level.goals_data.size(), 1)  # 단일 목표
    assert_eq(level.obstacles.size(), 0)   # 장애물 없음

func test_level_50_medium():
    var level = gen.generate(50)
    assert_lte(level.moves, 22)
    assert_gte(level.goals_data.size(), 2)
    assert_gt(level.obstacles.size(), 0)

func test_level_200_hard():
    var level = gen.generate(200)
    assert_lte(level.moves, 18)
    assert_gte(level.goals_data.size(), 2)

func test_moves_decrease_with_level():
    var level_10 = gen.generate(10)
    var level_100 = gen.generate(100)
    assert_gte(level_10.moves, level_100.moves)

func test_all_200_levels_valid():
    for i in range(1, 201):
        var level = gen.generate(i)
        assert_gt(level.moves, 0, "Level %d moves > 0" % i)
        assert_gt(level.goals_data.size(), 0, "Level %d has goals" % i)
```

- [ ] **Step 2: level_generator.gd 구현**

```gdscript
# src/core/level_generator.gd
class_name LevelGenerator

# 20개 공간 × 10스테이지 = 200레벨
# 공간 1-4: 지하 (쉬움)
# 공간 5-8: 1층 (보통)
# 공간 9-12: 2층 (어려움)
# 공간 13-16: 3층 (매우 어려움)
# 공간 17-20: 탈출 (극한)

const ROOM_NAMES := [
    "서버실", "감옥", "와인 저장고", "하수도",
    "우편물 창고", "식당", "휴게실", "환기 덕트",
    "문서 보관실", "인사팀", "회의실", "경리실",
    "감시실", "트로피 룸", "스파", "사장실",
    "엘리베이터", "옥상", "외벽", "정문"
]

func generate(level_id: int) -> LevelData:
    var data := LevelData.new()
    data.level_id = level_id

    var room := (level_id - 1) / 10  # 0-19
    var stage := (level_id - 1) % 10  # 0-9

    data.moves = _calculate_moves(room, stage)
    data.goals_data = _generate_goals(room, stage)
    data.obstacles = _generate_obstacles(room, stage)
    data.available_gems = _get_available_gems(room)
    data.board_cols = 8
    data.board_rows = 10

    return data

func get_room_name(level_id: int) -> String:
    var room := (level_id - 1) / 10
    return ROOM_NAMES[room] if room < ROOM_NAMES.size() else "Unknown"

func _calculate_moves(room: int, stage: int) -> int:
    # 기본 무브: 25 → 17 (공간 진행에 따라 감소)
    var base := 25 - room
    # 스테이지 내 추가 감소: 3단계마다 -1
    var stage_penalty := stage / 3
    return max(base - stage_penalty, 10)

func _generate_goals(room: int, stage: int) -> Array:
    var goals := []
    var goal_count := 1
    if stage >= 3:
        goal_count = 2
    if stage >= 7:
        goal_count = 3

    var gem_types := ["red", "blue", "green", "yellow", "purple"]
    var obstacle_types := ["box", "grass", "chain", "letter", "coin"]

    for i in range(goal_count):
        var amount := 10 + room * 2 + stage * 3
        if i == 0 and room < 5:
            goals.append({"type": gem_types[randi() % gem_types.size()], "amount": amount})
        else:
            goals.append({"type": obstacle_types[min(i, obstacle_types.size() - 1)], "amount": max(amount / 2, 5)})

    return goals

func _generate_obstacles(room: int, stage: int) -> Array:
    var obstacles := []
    if room < 1 and stage < 5:
        return obstacles  # 초반은 장애물 없음

    var count := (room + stage) / 2
    count = min(count, 15)

    var types := [Types.ObstacleType.STONE]
    if room >= 2:
        types.append(Types.ObstacleType.FENCE)
    if room >= 4:
        types.append(Types.ObstacleType.GRASS)
    if room >= 6:
        types.append(Types.ObstacleType.CHAIN)

    for i in range(count):
        var col := randi() % 8
        var row := randi() % 10
        obstacles.append({
            "col": col,
            "row": row,
            "type": types[randi() % types.size()],
            "hp": 1 + (room / 5)
        })

    return obstacles

func _get_available_gems(room: int) -> Array:
    if room < 3:
        return [0, 1, 2, 3, 4]  # 5종
    return [0, 1, 2, 3, 4, 5]  # 6종 (공간 4부터 오렌지 추가)
```

- [ ] **Step 3: 테스트 통과 & 커밋**

```bash
git add src/core/level_generator.gd tests/test_level_generator.gd
git commit -m "feat: Level Generator - 200레벨 자동 생성 (20공간×10스테이지, 난이도 스케일링)"
```

---

### Task 3.2: Save Manager (저장/로드)

**Files:**
- Create: `src/autoload/save_manager.gd`

- [ ] **Step 1: save_manager.gd 구현**

```gdscript
# src/autoload/save_manager.gd
extends Node

const SAVE_PATH := "user://save_data.json"

var data := {
    "current_level": 1,
    "stars": {},         # {"1": 3, "2": 2, ...}
    "coins": 0,
    "lives": 5,
    "boosters": {"hammer": 0, "shuffle": 0, "arrow": 0, "cannon": 0},
    "room_progress": {},  # {"1": {"tasks_done": [], "current_task": 0}}
    "total_stars": 0,
}

func _ready() -> void:
    load_game()

func save_game() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        var json := JSON.new()
        if json.parse(file.get_as_text()) == OK:
            var loaded = json.data
            if loaded is Dictionary:
                data.merge(loaded, true)

func complete_level(level_id: int, stars: int) -> void:
    var key := str(level_id)
    var prev_stars: int = data.stars.get(key, 0)
    if stars > prev_stars:
        data.stars[key] = stars
        data.total_stars += stars - prev_stars
    if level_id >= data.current_level:
        data.current_level = level_id + 1
    save_game()

func get_level_stars(level_id: int) -> int:
    return data.stars.get(str(level_id), 0)

func get_total_stars() -> int:
    return data.total_stars

func add_coins(amount: int) -> void:
    data.coins += amount
    save_game()

func use_life() -> bool:
    if data.lives > 0:
        data.lives -= 1
        save_game()
        return true
    return false
```

- [ ] **Step 2: 커밋**

```bash
git add src/autoload/save_manager.gd
git commit -m "feat: Save Manager - JSON 기반 진행도/코인/라이프/부스터 저장"
```

---

## Chunk 4: UI/UX & Visual Polish

**목표**: Royal Match 수준 HUD + 메뉴 시스템 + 파티클 이펙트 + 사운드

---

### Task 4.1: HUD (인게임 UI)

**Files:**
- Create: `src/ui/hud.tscn`
- Create: `src/ui/hud.gd`

- [ ] **Step 1: hud.gd 구현 (Royal Match 3단 HUD 참조)**

```gdscript
# src/ui/hud.gd
extends CanvasLayer

@onready var moves_label: Label = $MovesPanel/MovesLabel
@onready var target_container: VBoxContainer = $TargetPanel/TargetContainer
@onready var avatar: TextureRect = $AvatarPanel/Avatar
@onready var booster_bar: HBoxContainer = $BoosterBar

var _goal_labels: Dictionary = {}

func _ready() -> void:
    GameEvents.moves_changed.connect(_on_moves_changed)
    GameEvents.goal_progress.connect(_on_goal_progress)

func setup_level(moves: int, goals: Array) -> void:
    moves_label.text = str(moves)
    _goal_labels.clear()
    for child in target_container.get_children():
        child.queue_free()
    for goal in goals:
        var label := Label.new()
        label.text = "%s: 0/%d" % [goal.type, goal.amount]
        target_container.add_child(label)
        _goal_labels[goal.type] = label

func _on_moves_changed(remaining: int) -> void:
    moves_label.text = str(remaining)
    if remaining <= 5:
        moves_label.add_theme_color_override("font_color", Color.RED)

func _on_goal_progress(goal_type: String, current: int, target: int) -> void:
    if _goal_labels.has(goal_type):
        _goal_labels[goal_type].text = "%s: %d/%d" % [goal_type, current, target]
        if current >= target:
            _goal_labels[goal_type].add_theme_color_override("font_color", Color.GREEN)
```

- [ ] **Step 2: 커밋**

```bash
git add src/ui/hud.tscn src/ui/hud.gd
git commit -m "feat: HUD - 3단 구조 (Target/Avatar/Moves) + 부스터 바"
```

---

### Task 4.2-4.6: (UI 메뉴, 파티클, 사운드, 방 꾸미기 뷰)

> 상세 구현은 Chunk 4-6에서 동일한 TDD 패턴으로 진행.
> 각 Task: 테스트 작성 → 실패 확인 → 구현 → 통과 → 커밋

**Task 4.2**: Main Menu + Level Select (main_menu.gd, level_select.gd)
**Task 4.3**: Result Popup (result_popup.gd - 성공/실패/별점)
**Task 4.4**: Particle Manager (particle_manager.gd - 매치/TNT/로켓 이펙트)
**Task 4.5**: Audio Manager (audio_manager.gd - BGM + SFX)
**Task 4.6**: Booster Bar UI (booster_bar.gd - 4종 UI 부스터)

---

## Chunk 5: Meta Loop & Special Modes

**목표**: 방 꾸미기 메타 루프 + 곰사원 Nightmare 시간 제한 모드

---

### Task 5.1: Room Manager (방 꾸미기 시스템)

**Files:**
- Create: `src/meta/room_manager.gd`
- Create: `src/meta/room_task.gd`
- Create: `src/meta/area_progress.gd`
- Create: `src/data/room_data.gd`

- [ ] **Step 1: 에리어/태스크 데이터 구조**

```gdscript
# src/data/room_data.gd
class_name RoomData
extends Resource

@export var room_id: int
@export var name: String
@export var description: String
@export var tasks: Array = []  # [{"id": "build_desk", "name": "책상 설치", "star_cost": 2}]
@export var background_texture: String
@export var escape_description: String  # "전원 차단하여 탈출"
```

```gdscript
# src/meta/room_manager.gd
extends Node

var _rooms: Array = []
var _current_room: int = 0

func _ready() -> void:
    _generate_20_rooms()

func get_current_room() -> RoomData:
    return _rooms[_current_room] if _current_room < _rooms.size() else null

func complete_task(task_id: String) -> void:
    var room_save = SaveManager.data.room_progress.get(str(_current_room), {"tasks_done": [], "current_task": 0})
    if task_id not in room_save.tasks_done:
        room_save.tasks_done.append(task_id)
        SaveManager.data.room_progress[str(_current_room)] = room_save
        GameEvents.task_completed.emit(task_id)

    var room = get_current_room()
    if room and room_save.tasks_done.size() >= room.tasks.size():
        _current_room += 1
        GameEvents.area_completed.emit(_current_room - 1)
        SaveManager.save_game()

func get_area_progress() -> Dictionary:
    var room = get_current_room()
    if not room:
        return {"done": 0, "total": 0}
    var save = SaveManager.data.room_progress.get(str(_current_room), {"tasks_done": []})
    return {"done": save.tasks_done.size(), "total": room.tasks.size()}

func _generate_20_rooms() -> void:
    var names = LevelGenerator.ROOM_NAMES
    for i in range(20):
        var room := RoomData.new()
        room.room_id = i
        room.name = names[i]
        room.tasks = _generate_tasks(i)
        _rooms.append(room)

func _generate_tasks(room_id: int) -> Array:
    var task_count := 6 if room_id < 10 else 7
    var tasks := []
    for t in range(task_count):
        tasks.append({
            "id": "room_%d_task_%d" % [room_id, t],
            "name": "태스크 %d" % (t + 1),
            "star_cost": 1 + (t / 3)
        })
    return tasks
```

- [ ] **Step 2: 커밋**

```bash
git add src/meta/ src/data/room_data.gd
git commit -m "feat: Room Manager - 20개 공간 × 6~7 태스크 + 에리어 진행도"
```

---

### Task 5.2: 곰사원 Nightmare Mode (시간 제한 특수 스테이지)

**Files:**
- Create: `src/meta/nightmare_mode.gd`

- [ ] **Step 1: nightmare_mode.gd 구현**

```gdscript
# src/meta/nightmare_mode.gd
class_name NightmareMode
extends Node

signal time_expired()
signal rescue_progress(current: int, target: int)
signal rescue_complete()

var is_active: bool = false
var time_remaining: float = 60.0
var target_count: int = 65
var current_count: int = 0
var scenario: String = ""  # "fire", "dragon", "flood"

func start(p_scenario: String, p_time: float = 60.0, p_target: int = 65) -> void:
    scenario = p_scenario
    time_remaining = p_time
    target_count = p_target
    current_count = 0
    is_active = true

func _process(delta: float) -> void:
    if not is_active:
        return
    time_remaining -= delta
    if time_remaining <= 0:
        is_active = false
        time_expired.emit()

func add_progress(amount: int = 1) -> void:
    if not is_active:
        return
    current_count += amount
    rescue_progress.emit(current_count, target_count)
    if current_count >= target_count:
        is_active = false
        rescue_complete.emit()

# Nightmare 시나리오별 설정
# 공간 진행에 따라 등장 (5레벨마다 1회)
static func should_trigger(level_id: int) -> bool:
    return level_id % 10 == 5  # 각 공간의 5번째 스테이지

static func get_scenario_for_level(level_id: int) -> Dictionary:
    var room := (level_id - 1) / 10
    var scenarios := [
        {"scenario": "fire", "time": 60, "target": 50, "desc": "곰사원이 서버실 화재에 갇혔다!"},
        {"scenario": "flood", "time": 55, "target": 55, "desc": "하수도가 범람한다! 곰사원을 구출하라!"},
        {"scenario": "dragon", "time": 50, "target": 60, "desc": "악덕사장의 드래곤이 나타났다!"},
        {"scenario": "trap", "time": 45, "target": 65, "desc": "감시실 트랩이 작동했다!"},
    ]
    return scenarios[room % scenarios.size()]
```

- [ ] **Step 2: 커밋**

```bash
git add src/meta/nightmare_mode.gd
git commit -m "feat: 곰사원 Nightmare - 시간 제한 구출 모드 (fire/flood/dragon/trap)"
```

---

## Chunk 6: Mobile & Deploy

**목표**: 모바일 최적화 + 에셋 생성 + 배포

---

### Task 6.1: 에셋 생성 (Gemini CLI + nanobanana)

- [ ] **Step 1: 보석 6종 생성**

```bash
# 각 보석 64x64 PNG
for gem in red_gem blue_shield green_leaf yellow_crown pink_diamond orange_cup; do
    gemini -m gemini-2.0-flash-preview-image-generation \
        "nanobanana style, $gem, glossy 3D game piece, match-3 puzzle, transparent background, 64x64 pixels" \
        --output assets/sprites/gems/${gem}.png
done
```

- [ ] **Step 2: 부스터 5종 생성**

```bash
for booster in h_rocket v_rocket tnt lightball missile; do
    gemini -m gemini-2.0-flash-preview-image-generation \
        "nanobanana style, ${booster} power-up, game booster icon, glowing effect, transparent background, 64x64" \
        --output assets/sprites/boosters/${booster}.png
done
```

- [ ] **Step 3: 캐릭터 생성 (곰사원, 악덕사장)**

```bash
gemini -m gemini-2.0-flash-preview-image-generation \
    "nanobanana style, cute bear office worker, blue suit, tired expression, Korean salaryman, transparent background, 128x128" \
    --output assets/sprites/characters/bear_worker.png

gemini -m gemini-2.0-flash-preview-image-generation \
    "nanobanana style, evil boss character, red suit, angry expression, corporate villain, transparent background, 128x128" \
    --output assets/sprites/characters/boss_angry.png
```

- [ ] **Step 4: 커밋**

```bash
git add assets/
git commit -m "art: 게임 에셋 생성 - 보석6종/부스터5종/캐릭터2종 (nanobanana 스타일)"
```

---

### Task 6.2: Godot Export 설정

- [ ] **Step 1: export_presets.cfg 설정**

Mobile export (Android APK + iOS) + Web export (HTML5)

- [ ] **Step 2: 최적화**

```gdscript
# project.godot에 추가
[rendering]
renderer/rendering_method="mobile"
textures/canvas_textures/default_texture_filter=0  # Nearest for pixel-art feel
environment/defaults/default_clear_color=Color(0.1, 0.23, 0.56, 1)  # Royal Blue 배경
```

- [ ] **Step 3: 빌드 & 테스트 & 커밋**

```bash
godot --headless --export-all
git add export_presets.cfg project.godot
git commit -m "deploy: Godot export 설정 - Mobile(Android/iOS) + Web(HTML5)"
```

---

## Summary

| Chunk | Tasks | 예상 파일 수 | 핵심 테스트 |
|-------|-------|------------|-----------|
| 1 | 6 | 15 | match_detector, gravity, board_logic |
| 2 | 4 | 8 | booster_rules, executor, merger, obstacle |
| 3 | 2 | 4 | level_generator |
| 4 | 6 | 12 | HUD, 메뉴, 이펙트, 사운드 |
| 5 | 2 | 6 | room_manager, nightmare_mode |
| 6 | 2 | 4 | 에셋, export |

**Total**: 22 Tasks, ~49 Files, ~3,500 LOC (GDScript)

---

## Parallel Execution Guide

다음 작업들은 독립적으로 병렬 실행 가능:

| 병렬 그룹 | 작업 |
|-----------|------|
| **A** | Task 1.2 (Match Detector) + Task 1.3 (Gravity) |
| **B** | Task 2.1 (Booster Rules) + Task 2.3 (Booster Merger) + Task 2.4 (Obstacles) |
| **C** | Task 3.1 (Level Gen) + Task 3.2 (Save Manager) |
| **D** | Task 4.1-4.6 (모든 UI 작업) |
| **E** | Task 5.1 (Room) + Task 5.2 (Nightmare) |
| **F** | Task 6.1 (에셋) - 다른 모든 작업과 병렬 가능 |
