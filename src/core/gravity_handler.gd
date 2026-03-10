class_name GravityHandler


class FallMove:
	var from: Vector2i
	var to: Vector2i
	var gem_type: int

	func _init(p_from: Vector2i, p_to: Vector2i, p_gem_type: int) -> void:
		from = p_from
		to = p_to
		gem_type = p_gem_type


const EMPTY := -1


## 보드 상태를 기반으로 낙하 이동 목록을 계산한다.
## board[col][row] = gem_type (-1 = empty)
## cell_types[col][row] = CellType enum (optional, 미제공 시 모두 NORMAL 취급)
func calculate_falls(board: Array, cell_types: Array = []) -> Array:
	var cols := board.size()
	if cols == 0:
		return []
	var rows: int = board[0].size()

	# 작업용 보드 복사 (원본 변경 방지)
	var work_board: Array = []
	for col in cols:
		work_board.append(board[col].duplicate())

	var has_cell_types := cell_types.size() > 0
	var falls: Array = []

	# 수직 낙하: 각 열에서 아래→위 순으로 빈칸 채우기
	for col in cols:
		_apply_vertical_falls(work_board, cell_types, has_cell_types, col, rows, falls)

	# 대각선 낙하: 바로 아래가 BLANK이거나 막힌 경우 좌/우 대각선 시도
	_apply_diagonal_falls(work_board, cell_types, has_cell_types, cols, rows, falls)

	return falls


## 특정 열의 수직 낙하를 처리한다.
func _apply_vertical_falls(
	work_board: Array, cell_types: Array, has_cell_types: bool,
	col: int, rows: int, falls: Array
) -> void:
	# 아래에서 위로 스캔하며 빈칸을 찾고, 그 위의 보석을 떨어뜨린다
	var write_row := rows - 1  # 다음에 보석을 놓을 위치 (아래부터)

	# 먼저 BLANK가 아닌 셀만 추려서 아래부터 채운다
	# 단, BLANK 셀은 건너뛰어야 하므로 BLANK가 아닌 슬롯만 대상으로 한다
	var non_blank_slots: Array = []
	for row in range(rows - 1, -1, -1):
		if has_cell_types and cell_types[col][row] == Types.CellType.BLANK:
			continue
		non_blank_slots.append(row)

	# non_blank_slots: 아래부터 위 순서의 non-blank row 인덱스 목록
	# 이 슬롯들 사이에서 보석을 아래로 압축한다
	var gems_in_col: Array = []  # {row, gem_type} - 아래부터 위 순서
	for slot_row in non_blank_slots:
		if work_board[col][slot_row] != EMPTY:
			gems_in_col.append({
				"row": slot_row,
				"gem_type": work_board[col][slot_row]
			})

	# non_blank_slots의 앞쪽(아래쪽)부터 보석을 채워 넣는다
	for i in non_blank_slots.size():
		var target_row: int = non_blank_slots[i]
		if i < gems_in_col.size():
			var gem_info: Dictionary = gems_in_col[i]
			if gem_info["row"] != target_row:
				# 이동 발생
				falls.append(FallMove.new(
					Vector2i(col, gem_info["row"]),
					Vector2i(col, target_row),
					gem_info["gem_type"]
				))
			work_board[col][target_row] = gem_info["gem_type"]
		else:
			# 보석이 부족 → 빈칸으로 남김
			work_board[col][target_row] = EMPTY


## 대각선 낙하를 처리한다.
## 바로 아래가 BLANK이거나 채워진 상태에서, 대각선 아래가 비어있으면 이동한다.
func _apply_diagonal_falls(
	work_board: Array, cell_types: Array, has_cell_types: bool,
	cols: int, rows: int, falls: Array
) -> void:
	var changed := true
	while changed:
		changed = false
		# 아래에서 위로 스캔
		for row in range(rows - 1, 0, -1):
			for col in cols:
				if work_board[col][row] != EMPTY:
					continue
				# 이 빈칸이 BLANK면 건너뜀
				if has_cell_types and cell_types[col][row] == Types.CellType.BLANK:
					continue

				# 바로 위(row-1)에서 대각선으로 떨어질 수 있는 보석 탐색
				# 좌상(col-1, row-1), 우상(col+1, row-1) 순서로 시도
				for dc in [-1, 1]:
					var src_col := col + dc
					var src_row := row - 1
					if src_col < 0 or src_col >= cols:
						continue
					if work_board[src_col][src_row] == EMPTY:
						continue
					if has_cell_types and cell_types[src_col][src_row] == Types.CellType.BLANK:
						continue

					# 대각선 낙하 조건: 소스의 바로 아래가 막혀있거나 BLANK여야 함
					var below_src_row := src_row + 1
					var src_below_blocked := false
					if below_src_row >= rows:
						src_below_blocked = true
					elif has_cell_types and cell_types[src_col][below_src_row] == Types.CellType.BLANK:
						src_below_blocked = true
					elif work_board[src_col][below_src_row] != EMPTY:
						src_below_blocked = true

					if not src_below_blocked:
						continue

					# 대각선 이동 수행
					var gem_type: int = work_board[src_col][src_row]
					work_board[col][row] = gem_type
					work_board[src_col][src_row] = EMPTY
					falls.append(FallMove.new(
						Vector2i(src_col, src_row),
						Vector2i(col, row),
						gem_type
					))
					changed = true
					break  # 이 빈칸은 채워졌으므로 다음으로
