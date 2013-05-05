open HolKernel bossLib boolLib boolSimps listTheory relationTheory arithmeticTheory lcsymtacs
open miscTheory bytecodeTerminationTheory bytecodeEvalTheory rich_listTheory
val _ = intLib.deprecate_int()
val _ = new_theory"bytecodeExtra"

val bc_fetch_with_stack = store_thm("bc_fetch_with_stack",
  ``bc_fetch (s with stack := st) = bc_fetch s``,
  rw[bc_fetch_def])

val bump_pc_with_stack = store_thm("bump_pc_with_stack",
  ``bump_pc (s with stack := st) = (bump_pc s) with stack := st``,
  rw[bump_pc_def,bc_fetch_with_stack] >>
  BasicProvers.EVERY_CASE_TAC)

val bump_pc_inst_length = store_thm("bump_pc_inst_length",
  ``(bump_pc s).inst_length = s.inst_length``,
  rw[bump_pc_def] >> BasicProvers.CASE_TAC >> rw[])
val _ = export_rewrites["bump_pc_inst_length"]

val bc_fetch_aux_MAP = store_thm("bc_fetch_aux_MAP",
  ``!il f. (∀x. il (f x) = il x) ∧ (∀x. is_Label (f x) = is_Label x) ⇒
      ∀ls n. (bc_fetch_aux (MAP f ls) il n = OPTION_MAP f (bc_fetch_aux ls il n))``,
  ntac 2 gen_tac >> strip_tac >>
  Induct >> rw[bc_fetch_aux_def])

val bc_fetch_MAP = store_thm("bc_fetch_MAP",
  ``∀f s. (∀x. s.inst_length (f x) = s.inst_length x) ∧ (∀x. is_Label (f x) = is_Label x) ⇒
    (bc_fetch (s with <| code := MAP f s.code |>) = OPTION_MAP f (bc_fetch s))``,
  rw[bc_fetch_def,bc_fetch_aux_MAP])

val bc_find_loc_aux_NONE = store_thm("bc_find_loc_aux_NONE",
  ``∀il l ls n. (bc_find_loc_aux ls il l n = NONE) ⇒ ¬MEM (Label l) ls``,
  ntac 2 gen_tac >>
  Induct >> rw[bc_find_loc_aux_def] >>
  res_tac >> fs[])

val bc_find_loc_aux_MEM = store_thm("bc_find_loc_aux_MEM",
  ``∀il l ls n. (bc_find_loc_aux ls il l n ≠ NONE) ⇒ MEM (Label l) ls``,
  ntac 2 gen_tac >>
  Induct >> rw[bc_find_loc_aux_def] >>
  res_tac)

val dest_Label_def = Define`(dest_Label (Label n) = n)`
val _ = export_rewrites["dest_Label_def"]

val is_Label_rwt = store_thm("is_Label_rwt",
  ``∀i. is_Label i = ∃l. i = Label l``,
  Cases >> rw[])

val addr_of_el_def = Define`
  (addr_of_el il n [] = NONE) ∧
  (addr_of_el il n (x::xs) =
   if n = 0 then if is_Label x then NONE else SOME 0 else
     OPTION_BIND (addr_of_el il (n - 1) xs) (λm. SOME (m + (if is_Label x then 0 else il x + 1))))`
val _ = export_rewrites["addr_of_el_def"]

val bc_fetch_aux_addr_of_el = store_thm("bc_fetch_aux_addr_of_el",
  ``∀c il pc n. (addr_of_el il n c = SOME pc) ⇒ (bc_fetch_aux c il pc = SOME (EL n c))``,
  Induct >> rw[] >>
  Cases_on `n` >> fs[] >>
  spose_not_then strip_assume_tac >>
  DECIDE_TAC)

val bc_fetch_aux_not_label = store_thm("bc_fetch_aux_not_label",
  ``∀c il pc i. (bc_fetch_aux c il pc = SOME i) ⇒ ¬is_Label i``,
  Induct >> rw[] >> fs[] >> PROVE_TAC[])

val labels_only_def = Define`
  (labels_only (Jump (Addr _)) = F) ∧
  (labels_only (JumpIf (Addr _)) = F) ∧
  (labels_only (Call (Addr _)) = F) ∧
  (labels_only (PushPtr (Addr _)) = F) ∧
  (labels_only _ = T)`
val _ = export_rewrites["labels_only_def"]

val _ = Parse.overload_on("next_addr", ``λil ls. SUM (MAP (SUC o il) (FILTER ($~ o is_Label) ls))``)

val bc_fetch_next_addr = store_thm("bc_fetch_next_addr",
  ``∀bc0 bs x bc.
    (bs.code = bc0 ++ (x::bc)) ∧ (¬is_Label x) ∧
    (bs.pc = next_addr bs.inst_length bc0)
    ⇒
    (bc_fetch bs = SOME x)``,
  Induct >- rw[bc_fetch_def] >>
  rw[bc_fetch_def] >>
  fsrw_tac[ARITH_ss][bc_fetch_def,ADD1] >>
  first_x_assum (qspec_then `bs with <| code := TL bs.code ; pc := next_addr bs.inst_length bc0 |>` mp_tac) >>
  rw[])

val bc_find_loc_aux_thm = store_thm("bc_find_loc_aux_thm",
  ``∀il ls l n.
     bc_find_loc_aux ls il l n =
     if MEM (Label l) ls then
     SOME (n + SUM (MAP (SUC o il) (FILTER ($~ o is_Label) (TAKE (LEAST m. m < LENGTH ls ∧ (EL m ls = Label l)) ls))))
     else NONE``,
  gen_tac >> Induct >- rw[bc_find_loc_aux_def] >>
  simp[bc_find_loc_aux_def] >>
  qx_gen_tac `h` >> qx_gen_tac `l` >>
  Cases_on `h = Label l` >> fs[] >- (
    qx_gen_tac `n` >>
    qmatch_abbrev_tac `n = n + m` >>
    qsuff_tac `m = 0` >- rw[] >>
    unabbrev_all_tac >>
    numLib.LEAST_ELIM_TAC >>
    conj_tac >- (
      qexists_tac `0` >> rw[] ) >>
    gen_tac >>
    strip_tac >>
    first_x_assum (qspec_then `0` mp_tac) >>
    srw_tac[ARITH_ss][] ) >>
  Cases_on `MEM (Label l) ls` >> fs[] >>
  Q.PAT_ABBREV_TAC`l0 = $LEAST X` >>
  Q.PAT_ABBREV_TAC`l1 = $LEAST X` >>
  `(SUC l0) = l1` by (
    unabbrev_all_tac >>
    qmatch_abbrev_tac `SUC ($LEAST P) = X` >>
    `∃n. P n` by (
      fs[MEM_EL,Abbr`P`] >>
      PROVE_TAC[] ) >>
    rw[UNDISCH(Q.SPEC`n`SUC_LEAST)] >>
    unabbrev_all_tac >>
    AP_TERM_TAC >>
    rw[FUN_EQ_THM] >>
    Cases_on `m` >> rw[] ) >>
  srw_tac[ARITH_ss][])

val bc_find_loc_aux_ALL_DISTINCT = store_thm("bc_find_loc_aux_ALL_DISTINCT",
  ``∀ls il l n z k. ALL_DISTINCT (FILTER is_Label ls) ∧ (k < LENGTH ls) ∧ (EL k ls = Label l) ∧
    (z = n + next_addr il (TAKE k ls)) ⇒
    (bc_find_loc_aux ls il l n = SOME z)``,
  rw[bc_find_loc_aux_thm] >- (
   rw[MEM_EL] >> PROVE_TAC[] ) >>
  numLib.LEAST_ELIM_TAC >>
  conj_tac >- PROVE_TAC[] >>
  qx_gen_tac `j` >> rw[] >>
  qsuff_tac `k = j` >> rw[] >>
  match_mp_tac (Q.ISPEC`is_Label`ALL_DISTINCT_FILTER_EL_IMP) >>
  qexists_tac `ls` >> rw[])

val bc_fetch_aux_append_code = store_thm("bc_fetch_aux_append_code",
  ``∀il ls n l2 i. (bc_fetch_aux ls il n = SOME i) ⇒ (bc_fetch_aux (ls ++ l2) il n = SOME i)``,
    gen_tac >> Induct >> rw[bc_fetch_aux_def] )

val bc_fetch_append_code = store_thm("bc_fetch_append_code",
  ``(bc_fetch bs = SOME i) ⇒ (bc_fetch (bs with code := bs.code ++ c) = SOME i)``,
  rw[bc_fetch_def] >>
  imp_res_tac bc_fetch_aux_append_code >>
  rw[] )

val bc_find_loc_aux_append_code = store_thm("bc_find_loc_aux_append_code",
  ``∀il ls n l2 l i. (bc_find_loc_aux ls il n l = SOME i) ⇒ (bc_find_loc_aux (ls ++ l2) il n l = SOME i)``,
  gen_tac >> Induct >> rw[bc_find_loc_aux_def] )

val bc_find_loc_append_code = store_thm("bc_find_loc_append_code",
  ``(bc_find_loc bs l = SOME n) ⇒ (bc_find_loc (bs with code := bs.code ++ c) l = SOME n)``,
  Cases_on `l` >> rw[bc_find_loc_def] >>
  imp_res_tac bc_find_loc_aux_append_code >>
  rw[] )

val bc_state_component_equality = save_thm("bc_state_component_equality",
DB.fetch"Bytecode""bc_state_component_equality")

val bc_next_append_code = store_thm("bc_next_append_code",
  ``∀bs1 bs2. bc_next bs1 bs2 ⇒ ∀c0 c. (bs1.code = c0) ⇒ bc_next (bs1 with code := c0 ++ c) (bs2 with code := c0 ++ c)``,
  ho_match_mp_tac bc_next_ind >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    rw[bc_eval1_def] >>
    fs[bc_eval_stack_thm] >>
    rw[bump_pc_def] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] >>
    rw[bump_pc_with_stack] >>
    rw[bump_pc_def] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] >>
    rw[bc_state_component_equality] >>
    rw[bump_pc_def] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] >>
    rw[bc_state_component_equality] >>
    rw[bump_pc_def] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    rw[bc_eval1_def,LET_THM] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] >>
    rw[bc_state_component_equality] >>
    rw[bump_pc_def] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] ) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    srw_tac[ARITH_ss][bc_eval1_def,LET_THM] >>
    lrw[REVERSE_APPEND,EL_APPEND2,TAKE_APPEND2]) >>
  strip_tac >- (
    rw[bc_eval1_thm] >>
    imp_res_tac bc_fetch_append_code >>
    imp_res_tac bc_find_loc_append_code >>
    rw[bc_eval1_def,LET_THM] >>
    rw[bump_pc_def]) >>
  rw[bc_eval1_thm] >>
  imp_res_tac bc_fetch_append_code >>
  imp_res_tac bc_find_loc_append_code >>
  rw[bc_eval1_def,LET_THM] >>
  rw[bump_pc_def])

val bc_next_preserves_code = store_thm("bc_next_preserves_code",
  ``∀bs1 bs2. bc_next bs1 bs2 ⇒ (bs2.code = bs1.code)``,
  ho_match_mp_tac bc_next_ind >>
  rw[bump_pc_def] >>
  BasicProvers.EVERY_CASE_TAC >> rw[])

val RTC_bc_next_append_code = store_thm("RTC_bc_next_append_code",
  ``∀bs1 bs2 bs1c bs2c c. RTC bc_next bs1 bs2 ∧
    (bs1c = bs1 with code := bs1.code ++ c) ∧
    (bs2c = bs2 with code := bs2.code ++ c)
    ⇒ RTC bc_next bs1c bs2c``,
  rw[] >> (
     RTC_lifts_monotonicities
  |> Q.GEN`R` |> Q.ISPEC `bc_next`
  |> Q.GEN`f` |> Q.SPEC `λbs. bs with code := bs.code ++ c`
  |> strip_assume_tac) >> fs[] >> pop_assum (match_mp_tac o MP_CANON) >>
  rw[] >>
  imp_res_tac bc_next_append_code >> fs[] >>
  metis_tac[bc_next_preserves_code])

val _ = export_theory()
