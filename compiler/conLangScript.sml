(*Generated by Lem from conLang.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory astTheory semanticPrimitivesTheory lem_list_extraTheory bigStepTheory modLangTheory;

val _ = numLib.prefer_num();



val _ = new_theory "conLang"

(* Removes named datatype constructors. Follows modLang.
 *
 * The AST of conLang differs from modLang by using numbered tags instead of
 * constructor name identifiers for all data constructor patterns and
 * expressions. Constructors explicitly mention the type they are constructing.
 * Also type and exception declarations are removed.
 *
 * The values of conLang differ in that the closures do not contain a constructor
 * name environment.
 *
 * The semantics of conLang differ in that there is no lexical constructor name
 * environment. However, there is a mapping (exh_ctors_env) from types to the
 * (arity-indexed) tags of the constructors of that type. This is for use later
 * on in determining whether a pattern match is exhaustive.
 *
 * The translator to conLang keeps a mapping (tag_env) of each constructor to
 * its arity, tag, and type. Tags need only be unique for each arity-type pair,
 * and are reused as much as possible otherwise.
 *
 * The expressions include the unary operation for initialising the global
 * store, even though it can't be used until decLang. However, including it here
 * means that the conLang->decLang translation can just be (\x.x). Also
 * includes the expression for extending the global store.
 *
 *)

(*open import Pervasives*)
(*open import Lib*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import List_extra*)
(*open import BigStep*)
(*open import ModLang*)

(* these must match what the prim_types_program generates *)

(*val bind_tag : nat*)
val _ = Define `
 (bind_tag =( 0))`;


(*val chr_tag : nat*)
val _ = Define `
 (chr_tag =( 1))`;


(*val div_tag : nat*)
val _ = Define `
 (div_tag =( 2))`;


(*val eq_tag : nat*)
val _ = Define `
 (eq_tag =( 3))`;


(*val subscript_tag : nat*)
val _ = Define `
 (subscript_tag =( 4))`;


(*val true_tag : nat*)
val _ = Define `
 (true_tag =( 0))`;


(*val false_tag : nat*)
val _ = Define `
 (false_tag =( 1))`;


(*val nil_tag : nat*)
val _ = Define `
 (nil_tag =( 0))`;


(*val cons_tag : nat*)
val _ = Define `
 (cons_tag =( 0))`;


(*val none_tag : nat*)
val _ = Define `
 (none_tag =( 0))`;


(*val some_tag : nat*)
val _ = Define `
 (some_tag =( 0))`;


val _ = Hol_datatype `
 op_i2 =
    Op_i2 of op
  | Init_global_var_i2 of num`;


val _ = Hol_datatype `
 pat_i2 =
    Pvar_i2 of varN
  | Plit_i2 of lit
  | Pcon_i2 of  (num # tid_or_exn)option => pat_i2 list
  | Pref_i2 of pat_i2`;


val _ = Hol_datatype `
 exp_i2 =
    Raise_i2 of exp_i2
  | Handle_i2 of exp_i2 => (pat_i2 # exp_i2) list
  | Lit_i2 of lit
  | Con_i2 of  (num # tid_or_exn)option => exp_i2 list
  | Var_local_i2 of varN
  | Var_global_i2 of num
  | Fun_i2 of varN => exp_i2
  | App_i2 of op_i2 => exp_i2 list
  | If_i2 of exp_i2 => exp_i2 => exp_i2
  | Mat_i2 of exp_i2 => (pat_i2 # exp_i2) list
  | Let_i2 of  varN option => exp_i2 => exp_i2
  | Letrec_i2 of (varN # varN # exp_i2) list => exp_i2
  | Extend_global_i2 of num`;


val _ = Hol_datatype `
 dec_i2 =
    Dlet_i2 of num => exp_i2
  | Dletrec_i2 of (varN # varN # exp_i2) list`;


val _ = Hol_datatype `
 prompt_i2 =
    Prompt_i2 of dec_i2 list`;


val _ = Hol_datatype `
 v_i2 =
    Litv_i2 of lit
  | Conv_i2 of  (num # tid_or_exn)option => v_i2 list
  | Closure_i2 of (varN, v_i2) alist => varN => exp_i2
  | Recclosure_i2 of (varN, v_i2) alist => (varN # varN # exp_i2) list => varN
  | Loc_i2 of num
  | Vectorv_i2 of v_i2 list`;


(*val pat_bindings_i2 : pat_i2 -> list varN -> list varN*)
 val pat_bindings_i2_defn = Hol_defn "pat_bindings_i2" `

(pat_bindings_i2 (Pvar_i2 n) already_bound =  
(n::already_bound))
/\
(pat_bindings_i2 (Plit_i2 l) already_bound =
  already_bound)
/\
(pat_bindings_i2 (Pcon_i2 _ ps) already_bound =  
(pats_bindings_i2 ps already_bound))
/\
(pat_bindings_i2 (Pref_i2 p) already_bound =  
(pat_bindings_i2 p already_bound))
/\
(pats_bindings_i2 [] already_bound =
  already_bound)
/\
(pats_bindings_i2 (p::ps) already_bound =  
(pats_bindings_i2 ps (pat_bindings_i2 p already_bound)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn pat_bindings_i2_defn;

(* for each type, for each arity, the number of constructors of that arity *)
val _ = type_abbrev( "exh_ctors_env" , ``: (( typeN id), ( num spt)) fmap``);

(* for each constructor, its arity, tag, and type *)
val _ = type_abbrev( "flat_tag_env" , ``: (conN, (num # num # tid_or_exn)) fmap``);
val _ = type_abbrev( "tag_env" , ``: (modN, flat_tag_env) fmap # flat_tag_env``);

(*val lookup_tag_flat : conN -> flat_tag_env -> maybe (nat * tid_or_exn)*)
val _ = Define `
 (lookup_tag_flat cn ftagenv =  
((case FLOOKUP ftagenv cn of
      NONE => NONE
    | SOME (a,n,t) => SOME (n,t)
  )))`;


(*val lookup_tag_env : maybe (id conN) -> tag_env -> maybe (nat * tid_or_exn)*)
val _ = Define `
 (lookup_tag_env id (mtagenv,tagenv) =  
((case id of
      NONE => NONE
    | SOME (Short x) => lookup_tag_flat x tagenv
    | SOME (Long x y) =>
        (case FLOOKUP mtagenv x of
            NONE => NONE
          | SOME tagenv => lookup_tag_flat y tagenv
        )
  )))`;


(*val pat_to_i2 : tag_env -> pat -> pat_i2*)
 val pat_to_i2_defn = Hol_defn "pat_to_i2" `

(pat_to_i2 tagenv (Pvar x) = (Pvar_i2 x))
/\
(pat_to_i2 tagenv (Plit l) = (Plit_i2 l))
/\
(pat_to_i2 tagenv (Pcon con_id ps) =  
(Pcon_i2 (lookup_tag_env con_id tagenv) (MAP (pat_to_i2 tagenv) ps)))
/\
(pat_to_i2 tagenv (Pref p) = (Pref_i2 (pat_to_i2 tagenv p)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn pat_to_i2_defn;

(*val exp_to_i2 : tag_env -> exp_i1 -> exp_i2*)
(*val exps_to_i2 : tag_env -> list exp_i1 -> list exp_i2*)
(*val pat_exp_to_i2 : tag_env -> list (pat * exp_i1) -> list (pat_i2 * exp_i2)*)
(*val funs_to_i2 : tag_env -> list (varN * varN * exp_i1) -> list (varN * varN * exp_i2)*)
 val exp_to_i2_defn = Hol_defn "exp_to_i2" `

(exp_to_i2 tagenv (Raise_i1 e) =  
(Raise_i2 (exp_to_i2 tagenv e)))
/\
(exp_to_i2 tagenv (Handle_i1 e pes) =  
(Handle_i2 (exp_to_i2 tagenv e) (pat_exp_to_i2 tagenv pes)))
/\
(exp_to_i2 tagenv (Lit_i1 l) =  
(Lit_i2 l))
/\
(exp_to_i2 tagenv (Con_i1 cn es) =  
(Con_i2 (lookup_tag_env cn tagenv) (exps_to_i2 tagenv es)))
/\
(exp_to_i2 tagenv (Var_local_i1 x) = (Var_local_i2 x))
/\
(exp_to_i2 tagenv (Var_global_i1 x) = (Var_global_i2 x))
/\
(exp_to_i2 tagenv (Fun_i1 x e) =  
(Fun_i2 x (exp_to_i2 tagenv e)))
/\
(exp_to_i2 tagenv (App_i1 op es) =  
(App_i2 (Op_i2 op) (exps_to_i2 tagenv es)))
/\
(exp_to_i2 tagenv (If_i1 e1 e2 e3) =  
(If_i2 (exp_to_i2 tagenv e1) (exp_to_i2 tagenv e2) (exp_to_i2 tagenv e3)))
/\
(exp_to_i2 tagenv (Mat_i1 e pes) =  
(Mat_i2 (exp_to_i2 tagenv e) (pat_exp_to_i2 tagenv pes)))
/\
(exp_to_i2 tagenv (Let_i1 x e1 e2) =  
(Let_i2 x (exp_to_i2 tagenv e1) (exp_to_i2 tagenv e2)))
/\
(exp_to_i2 tagenv (Letrec_i1 funs e) =  
(Letrec_i2 (funs_to_i2 tagenv funs)
            (exp_to_i2 tagenv e)))
/\
(exps_to_i2 tagenv [] = ([]))
/\
(exps_to_i2 tagenv (e::es) =  
(exp_to_i2 tagenv e :: exps_to_i2 tagenv es))
/\
(pat_exp_to_i2 tagenv [] = ([]))
/\
(pat_exp_to_i2 tagenv ((p,e)::pes) =  
((pat_to_i2 tagenv p, exp_to_i2 tagenv e) :: pat_exp_to_i2 tagenv pes))
/\
(funs_to_i2 tagenv [] = ([]))
/\
(funs_to_i2 tagenv ((f,x,e)::funs) =  
((f,x,exp_to_i2 tagenv e) :: funs_to_i2 tagenv funs))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn exp_to_i2_defn;

(* next exception tag (arity-indexed),
 * current tag env,
 * current exh_ctors_env,
 * accumulator (for use on module exit) *)
val _ = type_abbrev( "tagenv_state" , ``:  num spt # tag_env # exh_ctors_env``);
val _ = type_abbrev( "tagenv_state_acc" , ``: tagenv_state # flat_tag_env``);

val _ = Define `
 (get_tagenv ((next,tagenv,exh),acc) = tagenv)`;

val _ = Define `
 (get_exh (next,tagenv,exh) = exh)`;


(*val insert_tag_env : conN -> (nat * nat * tid_or_exn) -> tag_env  -> tag_env*)
val _ = Define `
 (insert_tag_env cn tag (mtagenv,ftagenv) =
  (mtagenv,ftagenv |+ (cn, tag)))`;


(*val alloc_tag : tid_or_exn -> conN -> nat -> tagenv_state_acc -> tagenv_state_acc*)
val _ = Define `
 (alloc_tag tn cn arity ((next,tagenv,exh),acc) =  
((case tn of
    TypeExn _ =>
      let tag =        
((case sptree$lookup arity next of
          NONE => 0
        | SOME n => n
        )) in
      ((sptree$insert arity (tag+ 1) next,
        insert_tag_env cn (arity,tag,tn) tagenv,
        exh),acc |+ (cn, (arity,tag,tn)))
  | TypeId tid =>
      let (tag,exh) =        
((case FLOOKUP exh tid of
          NONE => ( 0,exh |+ (tid, (sptree$insert arity ( 1) sptree$LN)))
        | SOME m => (case sptree$lookup arity m of
                      NONE => ( 0,exh |+ (tid, (sptree$insert arity ( 1) m)))
                    | SOME t => (t,exh |+ (tid, (sptree$insert arity (t+ 1) m)))
                    )
        )) in
      ((next,
        insert_tag_env cn (arity,tag,tn) tagenv,
        exh),acc |+ (cn, (arity,tag,tn)))
  )))`;


(*val alloc_tags : maybe modN -> tagenv_state_acc -> type_def -> tagenv_state_acc*)
 val _ = Define `

(alloc_tags mn st [] = st)
/\
(alloc_tags mn st ((tvs,tn,constrs)::types) =  
(let st' =    
(FOLDL (\ st' (cn,ts) .  alloc_tag (TypeId (mk_id mn tn)) cn (LENGTH ts) st') st constrs)
  in
    alloc_tags mn st' types))`;


(*val decs_to_i2 : tagenv_state_acc -> list dec_i1 -> tagenv_state_acc * list dec_i2*)
 val _ = Define `

(decs_to_i2 st [] = (st,[]))
/\
(decs_to_i2 st (d::ds) =  
((case d of
      Dlet_i1 n e =>
        let (st', ds') = (decs_to_i2 st ds) in
          (st', (Dlet_i2 n (exp_to_i2 (get_tagenv st) e)::ds'))
    | Dletrec_i1 funs =>
        let (st', ds') = (decs_to_i2 st ds) in
          (st', (Dletrec_i2 (funs_to_i2 (get_tagenv st) funs)::ds'))
    | Dtype_i1 mn type_def =>
        let st'' = (alloc_tags mn st type_def) in
        let (st',ds') = (decs_to_i2 st'' ds) in
          (st', ds')
    | Dexn_i1 mn cn ts =>
        let (st', ds') = (decs_to_i2 (alloc_tag (TypeExn (mk_id mn cn)) cn (LENGTH ts) st) ds) in
          (st', ds')
  )))`;


(*val mod_tagenv : maybe modN -> flat_tag_env -> tag_env -> tag_env*)
val _ = Define `
 (mod_tagenv mn l (mtagenv,tagenv) =  
((case mn of
      NONE => (mtagenv,FUNION l tagenv)
    | SOME mn => (mtagenv |+ (mn, l),tagenv)
  )))`;


(*val prompt_to_i2 : tagenv_state -> prompt_i1 -> tagenv_state * prompt_i2*)
val _ = Define `
 (prompt_to_i2 tagenv_st prompt =  
((case prompt of
      Prompt_i1 mn ds =>
        let (((next',tagenv',exh'),acc'), ds') = (decs_to_i2 (tagenv_st,FEMPTY) ds) in
          ((next',mod_tagenv mn acc' (get_tagenv (tagenv_st,acc')),exh'), Prompt_i2 ds')
  )))`;


(*val prog_to_i2 : tagenv_state -> list prompt_i1 -> tagenv_state * list prompt_i2*)
 val _ = Define `

(prog_to_i2 st [] = (st, []))
/\
(prog_to_i2 st (p::ps) =  
(let (st',p') = (prompt_to_i2 st p) in
  let (st'',ps') = (prog_to_i2 st' ps) in
    (st'',(p'::ps'))))`;


(*val build_rec_env_i2 : list (varN * varN * exp_i2) -> alist varN v_i2 -> alist varN v_i2 -> alist varN v_i2*)
val _ = Define `
 (build_rec_env_i2 funs cl_env add_to_env =  
(FOLDR
    (\ (f,x,e) env' .  (f, Recclosure_i2 cl_env funs f) :: env')
    add_to_env
    funs))`;


(*val do_eq_i2 : v_i2 -> v_i2 -> eq_result*)
 val do_eq_i2_defn = Hol_defn "do_eq_i2" `

(do_eq_i2 (Litv_i2 l1) (Litv_i2 l2) =  
(if lit_same_type l1 l2 then Eq_val (l1 = l2)
  else Eq_type_error))
/\
(do_eq_i2 (Loc_i2 l1) (Loc_i2 l2) = (Eq_val (l1 = l2)))
/\
(do_eq_i2 (Conv_i2 NONE vs1) (Conv_i2 NONE vs2) =  
(if LENGTH vs1 = LENGTH vs2 then
    do_eq_list_i2 vs1 vs2
  else
    Eq_val F))
/\
(do_eq_i2 (Conv_i2 (SOME (n1,t1)) vs1) (Conv_i2 (SOME (n2,t2)) vs2) =  
(if ((n1,t1) = (n2,t2)) /\ (LENGTH vs1 = LENGTH vs2) then
    do_eq_list_i2 vs1 vs2
  else
    (case (t1,t2) of
      (TypeId s1,TypeId s2) =>
        if s1 = s2 then
          Eq_val F (* different constructors, same type *)
        else
          Eq_type_error (* type mismatch *)
    | (TypeExn s1, TypeExn s2) =>
        if s1 = s2 then
          (* same exception but different tags or arities *)
          Eq_type_error
        else if (n1 = n2) /\ (LENGTH vs1 = LENGTH vs2) then
          (* different exceptions but same tag and arity *)
          Eq_type_error
        else
          Eq_val F
    | _ => (* type mismatch *) Eq_type_error
    )))
/\
(do_eq_i2 (Vectorv_i2 vs1) (Vectorv_i2 vs2) =  
(if LENGTH vs1 = LENGTH vs2 then
    do_eq_list_i2 vs1 vs2
  else
    Eq_val F))
/\
(do_eq_i2 (Closure_i2 _ _ _) (Closure_i2 _ _ _) = Eq_closure)
/\
(do_eq_i2 (Closure_i2 _ _ _) (Recclosure_i2 _ _ _) = Eq_closure)
/\
(do_eq_i2 (Recclosure_i2 _ _ _) (Closure_i2 _ _ _) = Eq_closure)
/\
(do_eq_i2 (Recclosure_i2 _ _ _) (Recclosure_i2 _ _ _) = Eq_closure)
/\
(do_eq_i2 _ _ = Eq_type_error)
/\
(do_eq_list_i2 [] [] = (Eq_val T))
/\
(do_eq_list_i2 (v1::vs1) (v2::vs2) =  
((case do_eq_i2 v1 v2 of
      Eq_closure => Eq_closure
    | Eq_type_error => Eq_type_error
    | Eq_val r =>
        if ~ r then
          Eq_val F
        else
          do_eq_list_i2 vs1 vs2
  )))
/\
(do_eq_list_i2 _ _ = (Eq_val F))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn do_eq_i2_defn;

val _ = type_abbrev( "all_env_i2" , ``: (exh_ctors_env # ( v_i2 option) list # (varN, v_i2) alist)``);

val _ = Define `
 (all_env_i2_to_genv (exh,genv,env) = genv)`;

val _ = Define `
 (all_env_i2_to_env (exh,genv,env) = env)`;


(*val exn_env_i2 : alist varN v_i2*)
val _ = Define `
 (exn_env_i2 = ([]))`;


(*val do_opapp_i2 : list v_i2 -> maybe (alist varN v_i2 * exp_i2)*)
val _ = Define `
 (do_opapp_i2 vs =  
((case vs of
      [Closure_i2 env n e; v] =>
        SOME (((n,v)::env), e)
    | [Recclosure_i2 env funs n; v] =>
        if ALL_DISTINCT (MAP (\ (f,x,e) .  f) funs) then
          (case find_recfun n funs of
              SOME (n,e) => SOME (((n,v)::build_rec_env_i2 funs env env), e)
            | NONE => NONE
          )
        else
          NONE
    | _ => NONE
  )))`;


(*val prim_exn_i2 : nat -> conN -> v_i2*)
val _ = Define `
 (prim_exn_i2 tag cn = (Conv_i2 (SOME (tag, (TypeExn (Short cn)))) []))`;


(*val v_to_list_i2 : v_i2 -> maybe (list v_i2)*)
 val _ = Define `
 (v_to_list_i2 (Conv_i2 (SOME (tag, (TypeId (Short tn)))) []) =  
(if (tag = nil_tag) /\ (tn = "list") then
    SOME []
  else
    NONE))
/\ (v_to_list_i2 (Conv_i2 (SOME (tag, (TypeId (Short tn)))) [v1;v2]) =  
(if (tag = cons_tag)  /\ (tn = "list") then
    (case v_to_list_i2 v2 of
        SOME vs => SOME (v1::vs)
      | NONE => NONE
    )
  else
    NONE))
/\ (v_to_list_i2 _ = NONE)`;


(*val v_i2_to_char_list : v_i2 -> maybe (list char)*)
 val _ = Define `
 (v_i2_to_char_list (Conv_i2 (SOME (tag, (TypeId (Short tn)))) []) =  
(if (tag = nil_tag) /\ (tn = "list") then
    SOME []
  else
    NONE))
/\ (v_i2_to_char_list (Conv_i2 (SOME (tag, (TypeId (Short tn)))) [Litv_i2 (Char c);v]) =  
(if (tag = cons_tag)  /\ (tn = "list") then
    (case v_i2_to_char_list v of
        SOME cs => SOME (c::cs)
      | NONE => NONE
    )
  else
    NONE))
/\ (v_i2_to_char_list _ = NONE)`;


(*val char_list_to_v_i2 : list char -> v_i2*)
 val char_list_to_v_i2_defn = Hol_defn "char_list_to_v_i2" `
 (char_list_to_v_i2 [] = (Conv_i2 (SOME (nil_tag, (TypeId (Short "list")))) []))
/\ (char_list_to_v_i2 (c::cs) =  
(Conv_i2 (SOME (cons_tag, (TypeId (Short "list")))) [Litv_i2 (Char c); char_list_to_v_i2 cs]))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn char_list_to_v_i2_defn;

val _ = Define `
 (Boolv_i2 b = (Conv_i2 (SOME ((if b then true_tag else false_tag), TypeId(Short"bool"))) []))`;


(*val do_app_i2 : store v_i2 -> op_i2 -> list v_i2 -> maybe (store v_i2 * result v_i2 v_i2)*)
val _ = Define `
 (do_app_i2 s op vs =  
((case (op, vs) of
      (Op_i2 (Opn op), [Litv_i2 (IntLit n1); Litv_i2 (IntLit n2)]) =>
        if ((op = Divide) \/ (op = Modulo)) /\ (n2 =( 0 : int)) then
          SOME (s, Rerr (Rraise (prim_exn_i2 div_tag "Div")))
        else
          SOME (s, Rval (Litv_i2 (IntLit (opn_lookup op n1 n2))))
    | (Op_i2 (Opb op), [Litv_i2 (IntLit n1); Litv_i2 (IntLit n2)]) =>
        SOME (s, Rval (Boolv_i2 (opb_lookup op n1 n2)))
    | (Op_i2 Equality, [v1; v2]) =>
        (case do_eq_i2 v1 v2 of
            Eq_type_error => NONE
          | Eq_closure => SOME (s, Rerr (Rraise (prim_exn_i2 eq_tag "Eq")))
          | Eq_val b => SOME (s, Rval (Boolv_i2 b))
        )
    | (Op_i2 Opassign, [Loc_i2 lnum; v]) =>
        (case store_assign lnum (Refv v) s of
            SOME st => SOME (st, Rval (Conv_i2 NONE []))
          | NONE => NONE
        )
    | (Op_i2 Opref, [v]) =>
        let (s',n) = (store_alloc (Refv v) s) in
          SOME (s', Rval (Loc_i2 n))
    | (Op_i2 Opderef, [Loc_i2 n]) =>
        (case store_lookup n s of
            SOME (Refv v) => SOME (s,Rval v)
          | _ => NONE
        )
    | (Init_global_var_i2 idx, _) => NONE
    | (Op_i2 Aw8alloc, [Litv_i2 (IntLit n); Litv_i2 (Word8 w)]) =>
        if n <( 0 : int) then
          SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
        else
          let (s',lnum) =            
(store_alloc (W8array (REPLICATE (Num (ABS ( n))) w)) s)
          in 
            SOME (s', Rval (Loc_i2 lnum))
    | (Op_i2 Aw8sub, [Loc_i2 lnum; Litv_i2 (IntLit i)]) =>
        (case store_lookup lnum s of
            SOME (W8array ws) =>
              if i <( 0 : int) then
                SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
              else
                let n = (Num (ABS ( i))) in
                  if n >= LENGTH ws then
                    SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
                  else 
                    SOME (s, Rval (Litv_i2 (Word8 (EL n ws))))
          | _ => NONE
        )
    | (Op_i2 Aw8length, [Loc_i2 n]) =>
        (case store_lookup n s of
            SOME (W8array ws) =>
              SOME (s,Rval (Litv_i2(IntLit(int_of_num(LENGTH ws)))))
          | _ => NONE
         )
    | (Op_i2 Aw8update, [Loc_i2 lnum; Litv_i2(IntLit i); Litv_i2(Word8 w)]) =>
        (case store_lookup lnum s of
          SOME (W8array ws) =>
            if i <( 0 : int) then
              SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
            else 
              let n = (Num (ABS ( i))) in
                if n >= LENGTH ws then
                  SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
                else
                  (case store_assign lnum (W8array (LUPDATE w n ws)) s of
                      NONE => NONE
                    | SOME s' => SOME (s', Rval (Conv_i2 NONE []))
                  )
        | _ => NONE
      )
    | (Op_i2 Ord, [Litv_i2 (Char c)]) =>
          SOME (s, Rval (Litv_i2(IntLit(int_of_num(ORD c)))))
    | (Op_i2 Chr, [Litv_i2 (IntLit i)]) =>
        SOME (s,          
(if (i <( 0 : int)) \/ (i >( 255 : int)) then
            Rerr (Rraise (prim_exn_i2 chr_tag "Chr"))
          else
            Rval (Litv_i2(Char(CHR(Num (ABS ( i))))))))
    | (Op_i2 (Chopb op), [Litv_i2 (Char c1); Litv_i2 (Char c2)]) =>
        SOME (s, Rval (Boolv_i2 (opb_lookup op (int_of_num(ORD c1)) (int_of_num(ORD c2)))))
    | (Op_i2 Implode, [v]) =>
          (case v_i2_to_char_list v of
            SOME ls =>
              SOME (s, Rval (Litv_i2 (StrLit (IMPLODE ls))))
          | NONE => NONE
          )
    | (Op_i2 Explode, [Litv_i2 (StrLit str)]) =>
        SOME (s, Rval (char_list_to_v_i2 (EXPLODE str)))
    | (Op_i2 Strlen, [Litv_i2 (StrLit str)]) =>
        SOME (s, Rval (Litv_i2(IntLit(int_of_num(STRLEN str)))))
    | (Op_i2 VfromList, [v]) =>
          (case v_to_list_i2 v of
              SOME vs =>
                SOME (s, Rval (Vectorv_i2 vs))
            | NONE => NONE
          )
    | (Op_i2 Vsub, [Vectorv_i2 vs; Litv_i2 (IntLit i)]) =>
        if i <( 0 : int) then
          SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
        else
          let n = (Num (ABS ( i))) in
            if n >= LENGTH vs then
              SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
            else 
              SOME (s, Rval (EL n vs))
    | (Op_i2 Vlength, [Vectorv_i2 vs]) =>
        SOME (s, Rval (Litv_i2 (IntLit (int_of_num (LENGTH vs)))))
    | (Op_i2 Aalloc, [Litv_i2 (IntLit n); v]) =>
        if n <( 0 : int) then
          SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
        else
          let (s',lnum) =            
(store_alloc (Varray (REPLICATE (Num (ABS ( n))) v)) s)
          in 
            SOME (s', Rval (Loc_i2 lnum))
    | (Op_i2 Asub, [Loc_i2 lnum; Litv_i2 (IntLit i)]) =>
        (case store_lookup lnum s of
            SOME (Varray vs) =>
              if i <( 0 : int) then
                SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
              else
                let n = (Num (ABS ( i))) in
                  if n >= LENGTH vs then
                    SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
                  else 
                    SOME (s, Rval (EL n vs))
          | _ => NONE
        )
    | (Op_i2 Alength, [Loc_i2 n]) =>
        (case store_lookup n s of
            SOME (Varray ws) =>
              SOME (s,Rval (Litv_i2 (IntLit(int_of_num(LENGTH ws)))))
          | _ => NONE
         )
    | (Op_i2 Aupdate, [Loc_i2 lnum; Litv_i2 (IntLit i); v]) =>
        (case store_lookup lnum s of
          SOME (Varray vs) =>
            if i <( 0 : int) then
              SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
            else 
              let n = (Num (ABS ( i))) in
                if n >= LENGTH vs then
                  SOME (s, Rerr (Rraise (prim_exn_i2 subscript_tag "Subscript")))
                else
                  (case store_assign lnum (Varray (LUPDATE v n vs)) s of
                      NONE => NONE
                    | SOME s' => SOME (s', Rval (Conv_i2 NONE []))
                  )
        | _ => NONE
      )
    | _ => NONE
  )))`;


(*val do_if_i2 : v_i2 -> exp_i2 -> exp_i2 -> maybe exp_i2*)
val _ = Define `
 (do_if_i2 v e1 e2 =  
(if v = (Boolv_i2 T) then
    SOME e1
  else if v = (Boolv_i2 F) then
    SOME e2
  else
    NONE))`;


(*val pmatch_i2 : exh_ctors_env -> store v_i2 -> pat_i2 -> v_i2 -> alist varN v_i2 -> match_result (alist varN v_i2)*)
 val pmatch_i2_defn = Hol_defn "pmatch_i2" `

(pmatch_i2 exh s (Pvar_i2 x) v' env = (Match ((x,v')::env)))
/\
(pmatch_i2 exh s (Plit_i2 l) (Litv_i2 l') env =  
(if l = l' then
    Match env
  else if lit_same_type l l' then
    No_match
  else
    Match_type_error))
/\
(pmatch_i2 exh s (Pcon_i2 (SOME (n, (TypeExn t))) ps) (Conv_i2 (SOME (n', (TypeExn t'))) vs) env =  
(if (n = n') /\ (LENGTH ps = LENGTH vs) then
    if t = t' then
      pmatch_list_i2 exh s ps vs env
    else
      Match_type_error
  else if t = t' then
    Match_type_error
  else
    No_match))
/\
(pmatch_i2 exh s (Pcon_i2 (SOME (n, (TypeId t))) ps) (Conv_i2 (SOME (n', (TypeId t'))) vs) env =  
(if t = t' then
    (case FLOOKUP exh t of
        NONE => Match_type_error
      | SOME m =>
          let a = (LENGTH ps) in
          (case sptree$lookup a m of
            NONE => Match_type_error
          | SOME max =>
              if (n = n') /\ (a = LENGTH vs) then
                if n < max then
                  pmatch_list_i2 exh s ps vs env
                else Match_type_error
              else
                (case sptree$lookup (LENGTH vs) m of
                  NONE => Match_type_error
                | SOME max' =>
                    if (n < max) /\ (n' < max') then
                      No_match
                    else Match_type_error
                )
          )
    )
  else Match_type_error))
/\
(pmatch_i2 exh s (Pcon_i2 NONE ps) (Conv_i2 NONE vs) env =  
(if LENGTH ps = LENGTH vs then
    pmatch_list_i2 exh s ps vs env
  else
    Match_type_error))
/\
(pmatch_i2 exh s (Pref_i2 p) (Loc_i2 lnum) env =  
((case store_lookup lnum s of
      SOME (Refv v) => pmatch_i2 exh s p v env
    | _ => Match_type_error
  )))
/\
(pmatch_i2 exh _ _ _ env = Match_type_error)
/\
(pmatch_list_i2 exh s [] [] env = (Match env))
/\
(pmatch_list_i2 exh s (p::ps) (v::vs) env =  
((case pmatch_i2 exh s p v env of
      No_match => No_match
    | Match_type_error => Match_type_error
    | Match env' => pmatch_list_i2 exh s ps vs env'
  )))
/\
(pmatch_list_i2 exh s _ _ env = Match_type_error)`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn pmatch_i2_defn;


val _ = Hol_reln ` (! ck env l s.
T
==>
evaluate_i2 ck env s (Lit_i2 l) (s, Rval (Litv_i2 l)))

/\ (! ck env e s1 s2 v.
(evaluate_i2 ck s1 env e (s2, Rval v))
==>
evaluate_i2 ck s1 env (Raise_i2 e) (s2, Rerr (Rraise v)))

/\ (! ck env e s1 s2 err.
(evaluate_i2 ck s1 env e (s2, Rerr err))
==>
evaluate_i2 ck s1 env (Raise_i2 e) (s2, Rerr err))

/\ (! ck s1 s2 env e v pes.
(evaluate_i2 ck s1 env e (s2, Rval v))
==>
evaluate_i2 ck s1 env (Handle_i2 e pes) (s2, Rval v))

/\ (! ck s1 s2 env e pes v bv.
(evaluate_i2 ck env s1 e (s2, Rerr (Rraise v)) /\
evaluate_match_i2 ck env s2 v pes v bv)
==>
evaluate_i2 ck env s1 (Handle_i2 e pes) bv)

/\ (! ck s1 s2 env e pes err.
(evaluate_i2 ck env s1 e (s2, Rerr err) /\
((err = Rtimeout_error) \/ (err = Rtype_error)))
==>
evaluate_i2 ck env s1 (Handle_i2 e pes) (s2, Rerr err))

/\ (! ck env tag es vs s s'.
(evaluate_list_i2 ck env s (REVERSE es) (s', Rval vs))
==>
evaluate_i2 ck env s (Con_i2 tag es) (s', Rval (Conv_i2 tag (REVERSE vs))))

/\ (! ck env tag es err s s'.
(evaluate_list_i2 ck env s (REVERSE es) (s', Rerr err))
==>
evaluate_i2 ck env s (Con_i2 tag es) (s', Rerr err))

/\ (! ck env n v s.
(ALOOKUP (all_env_i2_to_env env) n = SOME v)
==>
evaluate_i2 ck env s (Var_local_i2 n) (s, Rval v))

/\ (! ck env n s.
(ALOOKUP (all_env_i2_to_env env) n = NONE)
==>
evaluate_i2 ck env s (Var_local_i2 n) (s, Rerr Rtype_error))

/\ (! ck env n v s.
((LENGTH (all_env_i2_to_genv env) > n) /\
(EL n (all_env_i2_to_genv env) = SOME v))
==>
evaluate_i2 ck env s (Var_global_i2 n) (s, Rval v))

/\ (! ck env n s.
((LENGTH (all_env_i2_to_genv env) > n) /\
(EL n (all_env_i2_to_genv env) = NONE))
==>
evaluate_i2 ck env s (Var_global_i2 n) (s, Rerr Rtype_error))

/\ (! ck env n s.
(~ (LENGTH (all_env_i2_to_genv env) > n))
==>
evaluate_i2 ck env s (Var_global_i2 n) (s, Rerr Rtype_error))

/\ (! ck env n e s.
T
==>
evaluate_i2 ck env s (Fun_i2 n e) (s, Rval (Closure_i2 (all_env_i2_to_env env) n e)))

/\ (! ck exh genv env es vs env' e bv s1 s2 count.
(evaluate_list_i2 ck (exh,genv,env) s1 (REVERSE es) ((count,s2), Rval vs) /\
(do_opapp_i2 (REVERSE vs) = SOME (env', e)) /\
(ck ==> ~ (count =( 0))) /\
evaluate_i2 ck (exh,genv,env') ((if ck then count -  1 else count),s2) e bv)
==>
evaluate_i2 ck (exh,genv,env) s1 (App_i2 (Op_i2 Opapp) es) bv)

/\ (! ck env es vs env' e s1 s2 count.
(evaluate_list_i2 ck env s1 (REVERSE es) ((count,s2), Rval vs) /\
(do_opapp_i2 (REVERSE vs) = SOME (env', e)) /\
(count = 0) /\
ck)
==>
evaluate_i2 ck env s1 (App_i2 (Op_i2 Opapp) es) (( 0,s2), Rerr Rtimeout_error))

/\ (! ck env es vs s1 s2.
(evaluate_list_i2 ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_opapp_i2 (REVERSE vs) = NONE))
==>
evaluate_i2 ck env s1 (App_i2 (Op_i2 Opapp) es) (s2, Rerr Rtype_error))

/\ (! ck env op es vs res s1 s2 s3 count.
(evaluate_list_i2 ck env s1 (REVERSE es) ((count,s2), Rval vs) /\
(do_app_i2 s2 op (REVERSE vs) = SOME (s3, res)) /\
(op <> Op_i2 Opapp))
==>
evaluate_i2 ck env s1 (App_i2 op es) ((count,s3), res))

/\ (! ck env op es vs s1 s2 count.
(evaluate_list_i2 ck env s1 (REVERSE es) ((count,s2), Rval vs) /\
(do_app_i2 s2 op (REVERSE vs) = NONE) /\
(op <> Op_i2 Opapp))
==>
evaluate_i2 ck env s1 (App_i2 op es) ((count,s2), Rerr Rtype_error))

/\ (! ck env op es err s1 s2.
(evaluate_list_i2 ck env s1 (REVERSE es) (s2, Rerr err))
==>
evaluate_i2 ck env s1 (App_i2 op es) (s2, Rerr err))

/\ (! ck env e1 e2 e3 v e' bv s1 s2.
(evaluate_i2 ck env s1 e1 (s2, Rval v) /\
(do_if_i2 v e2 e3 = SOME e') /\
evaluate_i2 ck env s2 e' bv)
==>
evaluate_i2 ck env s1 (If_i2 e1 e2 e3) bv)

/\ (! ck env e1 e2 e3 v s1 s2.
(evaluate_i2 ck env s1 e1 (s2, Rval v) /\
(do_if_i2 v e2 e3 = NONE))
==>
evaluate_i2 ck env s1 (If_i2 e1 e2 e3) (s2, Rerr Rtype_error))

/\ (! ck env e1 e2 e3 err s s'.
(evaluate_i2 ck env s e1 (s', Rerr err))
==>
evaluate_i2 ck env s (If_i2 e1 e2 e3) (s', Rerr err))

/\ (! ck env e pes v bv s1 s2.
(evaluate_i2 ck env s1 e (s2, Rval v) /\
evaluate_match_i2 ck env s2 v pes (Conv_i2 (SOME (bind_tag,(TypeExn (Short "Bind")))) []) bv)
==>
evaluate_i2 ck env s1 (Mat_i2 e pes) bv)

/\ (! ck env e pes err s s'.
(evaluate_i2 ck env s e (s', Rerr err))
==>
evaluate_i2 ck env s (Mat_i2 e pes) (s', Rerr err))

/\ (! ck exh genv env n e1 e2 v bv s1 s2.
(evaluate_i2 ck (exh,genv,env) s1 e1 (s2, Rval v) /\
evaluate_i2 ck (exh,genv,opt_bind n v env) s2 e2 bv)
==>
evaluate_i2 ck (exh,genv,env) s1 (Let_i2 n e1 e2) bv)

/\ (! ck env n e1 e2 err s s'.
(evaluate_i2 ck env s e1 (s', Rerr err))
==>
evaluate_i2 ck env s (Let_i2 n e1 e2) (s', Rerr err))

/\ (! ck exh genv env funs e bv s.
(ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs) /\
evaluate_i2 ck (exh,genv,build_rec_env_i2 funs env env) s e bv)
==>
evaluate_i2 ck (exh,genv,env) s (Letrec_i2 funs e) bv)

/\ (! ck env funs e s.
(~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)))
==>
evaluate_i2 ck env s (Letrec_i2 funs e) (s, Rerr Rtype_error))

/\ (! ck env n s.
T
==>
evaluate_i2 ck env s (Extend_global_i2 n) (s, Rerr Rtype_error))

/\ (! ck env s.
T
==>
evaluate_list_i2 ck env s [] (s, Rval []))

/\ (! ck env e es v vs s1 s2 s3.
(evaluate_i2 ck env s1 e (s2, Rval v) /\
evaluate_list_i2 ck env s2 es (s3, Rval vs))
==>
evaluate_list_i2 ck env s1 (e::es) (s3, Rval (v::vs)))

/\ (! ck env e es err s s'.
(evaluate_i2 ck env s e (s', Rerr err))
==>
evaluate_list_i2 ck env s (e::es) (s', Rerr err))

/\ (! ck env e es v err s1 s2 s3.
(evaluate_i2 ck env s1 e (s2, Rval v) /\
evaluate_list_i2 ck env s2 es (s3, Rerr err))
==>
evaluate_list_i2 ck env s1 (e::es) (s3, Rerr err))

/\ (! ck env v s err_v.
T
==>
evaluate_match_i2 ck env s v [] err_v (s, Rerr (Rraise err_v)))

/\ (! ck exh genv env env' v p pes e bv s count err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
(pmatch_i2 exh s p v env = Match env') /\
evaluate_i2 ck (exh,genv,env') (count,s) e bv)
==>
evaluate_match_i2 ck (exh,genv,env) (count,s) v ((p,e)::pes) err_v bv)

/\ (! ck exh genv env v p e pes bv s count err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
(pmatch_i2 exh s p v env = No_match) /\
evaluate_match_i2 ck (exh,genv,env) (count,s) v pes err_v bv)
==>
evaluate_match_i2 ck (exh,genv,env) (count,s) v ((p,e)::pes) err_v bv)

/\ (! ck exh genv env v p e pes s count err_v.
(pmatch_i2 exh s p v env = Match_type_error)
==>
evaluate_match_i2 ck (exh,genv,env) (count,s) v ((p,e)::pes) err_v ((count,s), Rerr Rtype_error))

/\ (! ck env v p e pes s err_v.
(~ (ALL_DISTINCT (pat_bindings_i2 p [])))
==>
evaluate_match_i2 ck env s v ((p,e)::pes) err_v (s, Rerr Rtype_error))`;

val _ = Hol_reln ` (! ck exh genv n e vs s1 s2.
(evaluate_i2 ck (exh,genv,[]) s1 e (s2, Rval (Conv_i2 NONE vs)) /\
(LENGTH vs = n))
==>
evaluate_dec_i2 ck exh genv s1 (Dlet_i2 n e) (s2, Rval vs))

/\ (! ck exh genv n e vs s1 s2.
(evaluate_i2 ck (exh,genv,[]) s1 e (s2, Rval (Conv_i2 NONE vs)) /\ ~ ((LENGTH vs) = n))
==>
evaluate_dec_i2 ck exh genv s1 (Dlet_i2 n e) (s2, Rerr Rtype_error))

/\ (! ck exh genv n e v s1 s2.
(evaluate_i2 ck (exh,genv,[]) s1 e (s2, Rval v) /\
~ (? vs. v = Conv_i2 NONE vs))
==>
evaluate_dec_i2 ck exh genv s1 (Dlet_i2 n e) (s2, Rerr Rtype_error))

/\ (! ck exh genv n e err s s'.
(evaluate_i2 ck (exh,genv,[]) s e (s', Rerr err))
==>
evaluate_dec_i2 ck exh genv s (Dlet_i2 n e) (s', Rerr err))

/\ (! ck exh genv funs s.
T
==>
evaluate_dec_i2 ck exh genv s (Dletrec_i2 funs) (s, Rval (MAP (\ (f,x,e) .  Closure_i2 [] x e) funs)))`;

val _ = Hol_reln ` (! ck exh genv s.
T
==>
evaluate_decs_i2 ck exh genv s [] (s, [], NONE))

/\ (! ck exh s1 s2 genv d ds e.
(evaluate_dec_i2 ck exh genv s1 d (s2, Rerr e))
==>
evaluate_decs_i2 ck exh genv s1 (d::ds) (s2, [], SOME e))

/\ (! ck exh s1 s2 s3 genv d ds new_env new_env' r.
(evaluate_dec_i2 ck exh genv s1 d (s2, Rval new_env) /\
evaluate_decs_i2 ck exh (genv ++ MAP SOME new_env) s2 ds (s3, new_env', r))
==>
evaluate_decs_i2 ck exh genv s1 (d::ds) (s3, (new_env ++ new_env'), r))`;

 val _ = Define `

(num_defs [] =( 0))
/\
(num_defs (Dlet_i2 n _::ds) = (n + num_defs ds))
/\
(num_defs (Dletrec_i2 funs::ds) = (LENGTH funs + num_defs ds))`;


val _ = Hol_reln ` (! ck exh genv s1 ds s2 env.
(evaluate_decs_i2 ck exh genv s1 ds (s2,env,NONE))
==>
evaluate_prompt_i2 ck exh genv s1 (Prompt_i2 ds) (s2, MAP SOME env, NONE))

/\ (! ck exh genv s1 ds s2 env err.
(evaluate_decs_i2 ck exh genv s1 ds (s2,env,SOME err))
==>
evaluate_prompt_i2 ck exh genv s1 (Prompt_i2 ds) (s2,                                           
 (MAP SOME env ++ GENLIST (\n .  
  (case (n ) of ( _ ) => NONE )) (num_defs ds - LENGTH env)),
                                           SOME err))`;

val _ = Hol_reln ` (! ck exh genv s.
T
==>
evaluate_prog_i2 ck exh genv s [] (s, [], NONE))

/\ (! ck exh genv s1 prompt prompts s2 env2 s3 env3 r.
(evaluate_prompt_i2 ck exh genv s1 prompt (s2, env2, NONE) /\
evaluate_prog_i2 ck exh (genv++env2) s2 prompts (s3, env3, r))
==>
evaluate_prog_i2 ck exh genv s1 (prompt::prompts) (s3, (env2++env3), r))

/\ (! ck exh genv s1 prompt prompts s2 env2 err.
(evaluate_prompt_i2 ck exh genv s1 prompt (s2, env2, SOME err))
==>
evaluate_prog_i2 ck exh genv s1 (prompt::prompts) (s2, env2, SOME err))`;
val _ = export_theory()

