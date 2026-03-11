# HUD 수정 & 목표 진행 버그 수정 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** HUD 레이아웃을 Royal Match 참조 디자인에 맞게 개선하고, 젬 파괴 시 목표 진행이 업데이트되지 않는 버그를 수정한다.

**Architecture:** HUD는 CanvasLayer + tscn으로 구성되며, 목표 표시를 텍스트("red")에서 젬 아이콘+숫자로 변경한다. board.gd에서 매치 결과의 gem_type을 집계하여 GameManager.add_goal_progress()를 호출하는 로직을 추가한다.

**Tech Stack:** Godot 4.6, GDScript, tscn scene format

---

## 참조 정보

### 현재 문제점
1. **HUD 레이아웃**: TargetPanel 내용이 보이지 않음 (텍스트 색상이 배경과 동일), 폰트 스타일 없음, 정렬 불량
2. **"red" 텍스트**: 목표가 "red: 0/12" 텍스트로 표시됨. 실제 보이는 젬은 하트/보석/별 등 아이콘인데 "red"라는 이름은 의미 불명
3. **목표 진행 버그**: `board.gd`에서 젬 파괴 시 `GameManager.add_goal_progress()` 미호출 → 카운트 영원히 0

### 참조 디자인 (Royal Match frame-000200.png)
- 왼쪽: "Target" 라벨 + 젬 아이콘 + 목표 숫자 (예: 빨간 사각 아이콘 + "15")
- 중앙: 캐릭터 아바타 (원형 프레임)
- 오른쪽: "Moves" 라벨 + 큰 숫자

### 핵심 파일 (수정 전 상태)
- `src/ui/hud.gd` — HUD 스크립트, setup_level()에서 Label.new()로 "red: 0/12" 텍스트 생성
- `src/ui/hud.tscn` — HUD 씬, TopBar(HBoxContainer) > TargetPanel/AvatarPanel/MovesPanel
- `src/board/board.gd` — 보드 컨트롤러, try_swap()에서 매치 처리. add_goal_progress() 미호출
- `src/core/types.gd` — GemType enum(RED=0~ORANGE=5), 상수 정의
- `src/core/level_generator.gd` — GEM_NAMES = ["red","blue",...] 로컬 상수
- `src/autoload/game_manager.gd` — add_goal_progress(goal_type, amount) 메서드 존재하나 호출처 없음
- `src/board/gem.gd` — GEM_PATHS = ["res://assets/sprites/gems/gem_0.png", ...] 텍스처 경로

### 매치 처리 흐름 (현재)
```
board.try_swap() → BoardLogic.process_matches()
  → result.matches: Array[MatchResult] (각 MatchResult에 .gem_type: int, .cells: Array)
  → result.destroyed_cells: Array[Vector2i]
  → _destroy_matched(result.destroyed_cells) → 시각적 파괴만
  → GameManager.use_move() → moves 감소
  → ❌ GameManager.add_goal_progress() 호출 없음
```

---

## Chunk 1: 목표 진행 버그 수정

### Task 1: types.gd에 GEM_NAMES 상수 추가

**Files:**
- Modify: `src/core/types.gd:1-20`

- [ ] **Step 1: types.gd에 GEM_NAMES 상수 추가**

`src/core/types.gd` 파일의 `GEM_TYPES_COUNT` 아래에 추가:

```gdscript
const GEM_NAMES: Array[String] = ["red", "blue", "green", "yellow", "purple", "orange"]
```

이렇게 하면 gem_type(int) → goal_type(String) 변환을 어디서든 `Types.GEM_NAMES[gem_type]`으로 할 수 있다.

- [ ] **Step 2: level_generator.gd에서 로컬 GEM_NAMES를 Types 참조로 변경**

`src/core/level_generator.gd:11` 줄의 로컬 `GEM_NAMES` 상수를 삭제하고, 사용하는 곳(39줄)을 `Types.GEM_NAMES`로 변경:

```gdscript
# 삭제: const GEM_NAMES: Array[String] = ["red", "blue", "green", "yellow", "purple", "orange"]
# 39줄 변경:
			"type": Types.GEM_NAMES[i % Types.GEM_NAMES.size()],
```

- [ ] **Step 3: 커밋**

```bash
git add src/core/types.gd src/core/level_generator.gd
git commit -m "refactor: GEM_NAMES를 Types로 중앙화"
```

---

### Task 2: board.gd에 목표 진행 업데이트 로직 추가

**Files:**
- Modify: `src/board/board.gd:1-107`

- [ ] **Step 1: _update_goal_progress 함수 추가**

`src/board/board.gd` 파일 끝(107줄 이후)에 새 함수 추가:

```gdscript
func _update_goal_progress(matches: Array) -> void:
	var counts: Dictionary = {}
	for m in matches:
		if m.gem_type >= 0 and m.gem_type < Types.GEM_NAMES.size():
			var gem_name: String = Types.GEM_NAMES[m.gem_type]
			counts[gem_name] = counts.get(gem_name, 0) + m.cells.size()
	for goal_type in counts:
		GameManager.add_goal_progress(goal_type, counts[goal_type])
```

- [ ] **Step 2: try_swap()에서 _update_goal_progress 호출 추가**

`src/board/board.gd:60-62`를 수정. `_destroy_matched` 후, `GameManager.use_move()` 전에 호출:

기존:
```gdscript
	_destroy_matched(result.destroyed_cells)
	GameEvents.gems_matched.emit(result.destroyed_cells, result.matches[0].type if result.matches.size() > 0 else "")
	GameManager.use_move()
```

변경:
```gdscript
	_destroy_matched(result.destroyed_cells)
	_update_goal_progress(result.matches)
	GameEvents.gems_matched.emit(result.destroyed_cells, result.matches[0].type if result.matches.size() > 0 else "")
	GameManager.use_move()
```

- [ ] **Step 3: _run_cascade()에서도 _update_goal_progress 호출 추가**

`src/board/board.gd:85-90`의 캐스케이드 루프에서도 매치 파괴 후 목표 업데이트 필요.

기존:
```gdscript
		var result := _logic.process_matches()
		if not result.matched:
			break
		_destroy_matched(result.destroyed_cells)
		GameEvents.cascade_started.emit()
```

변경:
```gdscript
		var result := _logic.process_matches()
		if not result.matched:
			break
		_destroy_matched(result.destroyed_cells)
		_update_goal_progress(result.matches)
		GameEvents.cascade_started.emit()
```

- [ ] **Step 4: Godot에서 실행하여 검증**

1. 게임 실행 (F5)
2. 젬 3개 매치
3. HUD에서 해당 젬 타입의 카운트가 증가하는지 확인 (현재 "red: 3/12" 등)
4. 캐스케이드 발생 시 추가 카운트도 증가하는지 확인

- [ ] **Step 5: 커밋**

```bash
git add src/board/board.gd
git commit -m "fix: 젬 파괴 시 목표 진행 업데이트 추가"
```

---

## Chunk 2: HUD 레이아웃 & 폰트 개선

### Task 3: hud.tscn 레이아웃 재구성

**Files:**
- Modify: `src/ui/hud.tscn:1-45`

- [ ] **Step 1: hud.tscn을 참조 디자인에 맞게 재작성**

전체 `src/ui/hud.tscn` 파일을 다음으로 교체:

```
[gd_scene load_steps=2 format=3 uid="uid://hud_scene"]

[ext_resource type="Script" path="res://src/ui/hud.gd" id="1"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1")

[node name="TopBar" type="HBoxContainer" parent="."]
anchors_preset = 10
anchor_right = 1.0
offset_left = 8.0
offset_top = 8.0
offset_right = -8.0
offset_bottom = 80.0
grow_horizontal = 2
theme_override_constants/separation = 4

[node name="TargetPanel" type="PanelContainer" parent="TopBar"]
custom_minimum_size = Vector2(140, 0)
size_flags_horizontal = 3

[node name="TargetMargin" type="MarginContainer" parent="TopBar/TargetPanel"]
layout_mode = 2
theme_override_constants/margin_left = 8
theme_override_constants/margin_top = 4
theme_override_constants/margin_right = 8
theme_override_constants/margin_bottom = 4

[node name="TargetVBox" type="VBoxContainer" parent="TopBar/TargetPanel/TargetMargin"]
layout_mode = 2
theme_override_constants/separation = 2

[node name="TargetLabel" type="Label" parent="TopBar/TargetPanel/TargetMargin/TargetVBox"]
layout_mode = 2
horizontal_alignment = 1
text = "Target"
label_settings = SubResource("LabelSettings_target_header")

[node name="TargetContainer" type="VBoxContainer" parent="TopBar/TargetPanel/TargetMargin/TargetVBox"]
layout_mode = 2
theme_override_constants/separation = 2

[node name="AvatarPanel" type="PanelContainer" parent="TopBar"]
custom_minimum_size = Vector2(72, 0)
size_flags_horizontal = 0

[node name="Avatar" type="TextureRect" parent="TopBar/AvatarPanel"]
layout_mode = 2
expand_mode = 1
stretch_mode = 5

[node name="MovesPanel" type="PanelContainer" parent="TopBar"]
custom_minimum_size = Vector2(100, 0)
size_flags_horizontal = 3

[node name="MovesMargin" type="MarginContainer" parent="TopBar/MovesPanel"]
layout_mode = 2
theme_override_constants/margin_left = 8
theme_override_constants/margin_top = 4
theme_override_constants/margin_right = 8
theme_override_constants/margin_bottom = 4

[node name="MovesVBox" type="VBoxContainer" parent="TopBar/MovesPanel/MovesMargin"]
layout_mode = 2

[node name="MovesHeader" type="Label" parent="TopBar/MovesPanel/MovesMargin/MovesVBox"]
layout_mode = 2
horizontal_alignment = 1
text = "Moves"

[node name="MovesLabel" type="Label" parent="TopBar/MovesPanel/MovesMargin/MovesVBox"]
layout_mode = 2
horizontal_alignment = 1
vertical_alignment = 1
text = "20"

[node name="BoosterBar" type="HBoxContainer" parent="."]
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -60.0
grow_horizontal = 2
grow_vertical = 0
alignment = 1
```

주요 변경:
- TopBar에 좌우 margin(8px) 추가
- TargetPanel: MarginContainer 추가, "Target" 헤더 라벨 추가, TargetContainer를 그 아래로 이동
- MovesPanel: MarginContainer 추가, "Moves" 헤더 라벨 추가, MovesLabel 분리
- AvatarPanel: 사이즈 조정

- [ ] **Step 2: 커밋**

```bash
git add src/ui/hud.tscn
git commit -m "refactor: HUD tscn 레이아웃 재구성 (Target/Moves 헤더 추가)"
```

---

### Task 4: hud.gd 전면 개편 (아이콘 목표 + 폰트 스타일링)

**Files:**
- Modify: `src/ui/hud.gd:1-35`

- [ ] **Step 1: hud.gd를 아이콘 기반 목표 표시로 전면 재작성**

`src/ui/hud.gd` 전체를 다음으로 교체:

```gdscript
extends CanvasLayer

@onready var moves_label: Label = $TopBar/MovesPanel/MovesMargin/MovesVBox/MovesLabel
@onready var moves_header: Label = $TopBar/MovesPanel/MovesMargin/MovesVBox/MovesHeader
@onready var target_container: VBoxContainer = $TopBar/TargetPanel/TargetMargin/TargetVBox/TargetContainer
@onready var target_header: Label = $TopBar/TargetPanel/TargetMargin/TargetVBox/TargetLabel
@onready var avatar: TextureRect = $TopBar/AvatarPanel/Avatar

const GEM_PATHS := [
	"res://assets/sprites/gems/gem_0.png",
	"res://assets/sprites/gems/gem_1.png",
	"res://assets/sprites/gems/gem_2.png",
	"res://assets/sprites/gems/gem_3.png",
	"res://assets/sprites/gems/gem_4.png",
	"res://assets/sprites/gems/gem_5.png",
]

var _goal_labels: Dictionary = {}  # goal_type(String) → Label node
var _goal_type_to_index: Dictionary = {}

func _ready() -> void:
	GameEvents.moves_changed.connect(_on_moves_changed)
	GameEvents.goal_progress.connect(_on_goal_progress)
	_setup_type_mapping()
	_style_labels()

func _setup_type_mapping() -> void:
	for i in range(Types.GEM_NAMES.size()):
		_goal_type_to_index[Types.GEM_NAMES[i]] = i

func _style_labels() -> void:
	# Moves 숫자: 크고 굵게, 흰색
	var moves_settings := LabelSettings.new()
	moves_settings.font_size = 28
	moves_settings.font_color = Color.WHITE
	moves_settings.outline_size = 3
	moves_settings.outline_color = Color(0, 0, 0, 0.6)
	moves_label.label_settings = moves_settings

	# Moves 헤더: 작고 밝은 회색
	var header_settings := LabelSettings.new()
	header_settings.font_size = 11
	header_settings.font_color = Color(0.8, 0.85, 0.9, 1.0)
	moves_header.label_settings = header_settings

	# Target 헤더도 동일
	target_header.label_settings = header_settings

func setup_level(moves: int, goals: Array) -> void:
	moves_label.text = str(moves)
	_goal_labels.clear()
	for child in target_container.get_children():
		child.queue_free()
	for goal in goals:
		_add_goal_row(goal.type, goal.amount)

func _add_goal_row(goal_type: String, target_amount: int) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)

	# 젬 아이콘
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var idx: int = _goal_type_to_index.get(goal_type, -1)
	if idx >= 0 and idx < GEM_PATHS.size():
		icon.texture = load(GEM_PATHS[idx])
	row.add_child(icon)

	# 카운트 라벨 ("0 / 12")
	var label := Label.new()
	var label_settings := LabelSettings.new()
	label_settings.font_size = 16
	label_settings.font_color = Color.WHITE
	label_settings.outline_size = 2
	label_settings.outline_color = Color(0, 0, 0, 0.5)
	label.label_settings = label_settings
	label.text = "0/%d" % target_amount
	row.add_child(label)

	target_container.add_child(row)
	_goal_labels[goal_type] = label

func _on_moves_changed(remaining: int) -> void:
	moves_label.text = str(remaining)
	if remaining <= 5:
		moves_label.label_settings.font_color = Color(1.0, 0.3, 0.3)

func _on_goal_progress(goal_type: String, current: int, target: int) -> void:
	if _goal_labels.has(goal_type):
		var label: Label = _goal_labels[goal_type]
		label.text = "%d/%d" % [current, target]
		if current >= target:
			label.label_settings.font_color = Color(0.3, 1.0, 0.3)
```

주요 변경:
- `@onready` 경로를 새 tscn 구조에 맞게 업데이트
- `_style_labels()`: LabelSettings로 폰트 크기/색상/아웃라인 설정
- `_add_goal_row()`: HBoxContainer(젬 아이콘 TextureRect + 카운트 Label) 생성
- "red" 텍스트 대신 `gem_0.png`(하트) 아이콘 표시
- 카운트 형식: "0/12" (아이콘 옆)

- [ ] **Step 2: Godot에서 실행하여 검증**

1. 게임 실행 (F5)
2. 확인 사항:
   - 왼쪽 상단: "Target" 헤더 + 하트 아이콘 + "0/12" 숫자
   - 오른쪽 상단: "Moves" 헤더 + 큰 숫자
   - 젬 매치 시 카운트 증가
   - moves ≤ 5일 때 숫자 빨간색
   - 목표 달성 시 숫자 초록색

- [ ] **Step 3: 커밋**

```bash
git add src/ui/hud.gd
git commit -m "feat: HUD를 아이콘 기반 목표 표시로 개선 (폰트/정렬/스타일링)"
```

---

### Task 5: 웹 빌드 & 배포 검증

**Files:**
- 없음 (빌드 & 배포 확인)

- [ ] **Step 1: Godot 에디터에서 웹 빌드**

Godot 에디터 → Project → Export → Web → Export Project
출력 경로: `build/web/index.html`

- [ ] **Step 2: 로컬에서 웹 빌드 테스트**

```bash
cd /Users/jaejin/projects/toy/royal-puzzle-3/build/web
python3 -m http.server 8080
```

브라우저에서 `http://localhost:8080` 접속하여 확인:
- HUD 레이아웃 정상
- 목표 아이콘 표시
- 매치 시 카운트 증가

- [ ] **Step 3: Vercel 배포 (기존 설정 활용)**

```bash
cd /Users/jaejin/projects/toy/royal-puzzle-3
vercel --prod
```

- [ ] **Step 4: 최종 커밋 (빌드 결과물 포함 시)**

```bash
git add build/web/
git commit -m "build: 웹 빌드 업데이트"
```
