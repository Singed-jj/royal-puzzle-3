class_name MatchDetector
extends RefCounted


class MatchResult:
	var cells: Array = []  # Array of Vector2i(col, row)
	var type: String = ""
	var gem_type: int = -1

	func _init(p_cells: Array = [], p_type: String = "", p_gem_type: int = -1) -> void:
		cells = p_cells
		type = p_type
		gem_type = p_gem_type


## 보드에서 모든 매치를 찾아 반환한다.
## board: Array[Array[int]] — board[col][row] = gem_type (-1 = empty)
func find_matches(board: Array) -> Array:
	var h_runs: Array = _find_horizontal_runs(board)
	var v_runs: Array = _find_vertical_runs(board)
	var results: Array = _merge_runs(h_runs, v_runs, board)
	return results


# ── 가로 연속 run 찾기 ──────────────────────────────────────────

func _find_horizontal_runs(board: Array) -> Array:
	var runs: Array = []
	for row in range(Types.BOARD_ROWS):
		var col := 0
		while col < Types.BOARD_COLS:
			var gem: int = _get_gem(board, col, row)
			if gem < 0:
				col += 1
				continue
			var end_col := col + 1
			while end_col < Types.BOARD_COLS and _get_gem(board, end_col, row) == gem:
				end_col += 1
			var length := end_col - col
			if length >= Types.MATCH_MIN:
				var cells: Array = []
				for c in range(col, end_col):
					cells.append(Vector2i(c, row))
				runs.append({"cells": cells, "gem_type": gem, "orientation": "h"})
			col = end_col
	return runs


# ── 세로 연속 run 찾기 ──────────────────────────────────────────

func _find_vertical_runs(board: Array) -> Array:
	var runs: Array = []
	for col in range(Types.BOARD_COLS):
		var row := 0
		while row < Types.BOARD_ROWS:
			var gem: int = _get_gem(board, col, row)
			if gem < 0:
				row += 1
				continue
			var end_row := row + 1
			while end_row < Types.BOARD_ROWS and _get_gem(board, col, end_row) == gem:
				end_row += 1
			var length := end_row - row
			if length >= Types.MATCH_MIN:
				var cells: Array = []
				for r in range(row, end_row):
					cells.append(Vector2i(col, r))
				runs.append({"cells": cells, "gem_type": gem, "orientation": "v"})
			row = end_row
	return runs


# ── run 병합 및 패턴 분류 ───────────────────────────────────────

func _merge_runs(h_runs: Array, v_runs: Array, _board: Array) -> Array:
	# 각 셀이 어떤 h_run / v_run에 속하는지 매핑
	var cell_to_h: Dictionary = {}  # Vector2i -> h_run index
	var cell_to_v: Dictionary = {}  # Vector2i -> v_run index

	for i in range(h_runs.size()):
		for cell in h_runs[i]["cells"]:
			cell_to_h[cell] = i

	for i in range(v_runs.size()):
		for cell in v_runs[i]["cells"]:
			cell_to_v[cell] = i

	# 교차점 찾기 — 같은 gem_type인 h_run과 v_run 쌍
	var used_h: Dictionary = {}  # h_run index -> bool
	var used_v: Dictionary = {}  # v_run index -> bool
	var results: Array = []

	# 1단계: 교차하는 run 쌍을 합쳐서 복합 패턴 생성
	var cross_groups: Array = _find_cross_groups(h_runs, v_runs, cell_to_h, cell_to_v)

	for group in cross_groups:
		var h_indices: Array = group["h_indices"]
		var v_indices: Array = group["v_indices"]
		var gem: int = group["gem_type"]

		# 모든 셀 합치기 (중복 제거)
		var all_cells: Dictionary = {}
		for hi in h_indices:
			for cell in h_runs[hi]["cells"]:
				all_cells[cell] = true
			used_h[hi] = true
		for vi in v_indices:
			for cell in v_runs[vi]["cells"]:
				all_cells[cell] = true
			used_v[vi] = true

		var merged_cells: Array = all_cells.keys()
		var h_lengths: Array = []
		for hi in h_indices:
			h_lengths.append(h_runs[hi]["cells"].size())
		var v_lengths: Array = []
		for vi in v_indices:
			v_lengths.append(v_runs[vi]["cells"].size())

		# 교차점 수집
		var intersections: Array = []
		for hi in h_indices:
			for vi in v_indices:
				var h_cells: Array = h_runs[hi]["cells"]
				var v_cells: Array = v_runs[vi]["cells"]
				for hc in h_cells:
					if v_cells.has(hc):
						intersections.append({"point": hc, "h_run": h_runs[hi], "v_run": v_runs[vi]})

		var match_type: String = _classify_complex_with_intersections(
			h_indices, v_indices, h_runs, v_runs, intersections)
		results.append(MatchResult.new(merged_cells, match_type, gem))

	# 2단계: 사용되지 않은 단독 run 처리
	for i in range(h_runs.size()):
		if not used_h.has(i):
			var run: Dictionary = h_runs[i]
			var length: int = run["cells"].size()
			var match_type: String = _classify_line(length, "horizontal")
			results.append(MatchResult.new(run["cells"].duplicate(), match_type, run["gem_type"]))

	for i in range(v_runs.size()):
		if not used_v.has(i):
			var run: Dictionary = v_runs[i]
			var length: int = run["cells"].size()
			var match_type: String = _classify_line(length, "vertical")
			results.append(MatchResult.new(run["cells"].duplicate(), match_type, run["gem_type"]))

	return results


# ── 교차 그룹 찾기 ──────────────────────────────────────────────

func _find_cross_groups(h_runs: Array, v_runs: Array,
		cell_to_h: Dictionary, cell_to_v: Dictionary) -> Array:
	# 교차점이 있는 (h, v) 쌍을 찾아 연결 컴포넌트로 그룹핑
	var h_to_v: Dictionary = {}  # h_index -> Array of v_index
	var v_to_h: Dictionary = {}  # v_index -> Array of h_index

	for cell in cell_to_h:
		if cell_to_v.has(cell):
			var hi: int = cell_to_h[cell]
			var vi: int = cell_to_v[cell]
			if h_runs[hi]["gem_type"] == v_runs[vi]["gem_type"]:
				if not h_to_v.has(hi):
					h_to_v[hi] = []
				if not h_to_v[hi].has(vi):
					h_to_v[hi].append(vi)
				if not v_to_h.has(vi):
					v_to_h[vi] = []
				if not v_to_h[vi].has(hi):
					v_to_h[vi].append(hi)

	# BFS로 연결 컴포넌트
	var visited_h: Dictionary = {}
	var visited_v: Dictionary = {}
	var groups: Array = []

	for hi in h_to_v:
		if visited_h.has(hi):
			continue
		var group_h: Array = []
		var group_v: Array = []
		var queue_h: Array = [hi]
		var queue_v: Array = []
		while queue_h.size() > 0 or queue_v.size() > 0:
			while queue_h.size() > 0:
				var h: int = queue_h.pop_back()
				if visited_h.has(h):
					continue
				visited_h[h] = true
				group_h.append(h)
				if h_to_v.has(h):
					for v in h_to_v[h]:
						if not visited_v.has(v):
							queue_v.append(v)
			while queue_v.size() > 0:
				var v: int = queue_v.pop_back()
				if visited_v.has(v):
					continue
				visited_v[v] = true
				group_v.append(v)
				if v_to_h.has(v):
					for h in v_to_h[v]:
						if not visited_h.has(h):
							queue_h.append(h)
		if group_h.size() > 0 and group_v.size() > 0:
			groups.append({
				"h_indices": group_h,
				"v_indices": group_v,
				"gem_type": h_runs[group_h[0]]["gem_type"],
			})

	return groups


# ── 복합 패턴 분류 (교차점 기반) ─────────────────────────────────

func _classify_complex_with_intersections(
		h_indices: Array, v_indices: Array,
		h_runs: Array, v_runs: Array,
		intersections: Array) -> String:
	var h_count: int = h_indices.size()
	var v_count: int = v_indices.size()

	if h_count == 1 and v_count == 1 and intersections.size() == 1:
		var ix: Dictionary = intersections[0]
		var point: Vector2i = ix["point"]
		var h_cells: Array = ix["h_run"]["cells"]
		var v_cells: Array = ix["v_run"]["cells"]

		# 교차점이 h_run의 양 끝이 아닌 내부에 있는지
		var h_interior: bool = (point != h_cells[0] and point != h_cells[h_cells.size() - 1])
		# 교차점이 v_run의 양 끝이 아닌 내부에 있는지
		var v_interior: bool = (point != v_cells[0] and point != v_cells[v_cells.size() - 1])

		if h_interior and v_interior:
			return "cross"
		elif h_interior or v_interior:
			return "t_shape"
		else:
			return "l_shape"

	# 여러 교차점이 있는 경우
	if h_count == 1 and v_count == 2:
		return "t_shape"
	if h_count == 2 and v_count == 1:
		return "t_shape"

	if h_count >= 2 and v_count >= 2:
		return "cross"

	return "l_shape"


# ── 단순 라인 분류 ──────────────────────────────────────────────

func _classify_line(length: int, orientation: String) -> String:
	if length >= 5:
		return orientation + "_5"
	elif length == 4:
		return orientation + "_4"
	else:
		return orientation


# ── 보드 접근 헬퍼 ──────────────────────────────────────────────

func _get_gem(board: Array, col: int, row: int) -> int:
	if col < 0 or col >= Types.BOARD_COLS or row < 0 or row >= Types.BOARD_ROWS:
		return -1
	return board[col][row]
