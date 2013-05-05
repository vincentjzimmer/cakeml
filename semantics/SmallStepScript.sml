(*Generated by Lem from smallStep.lem.*)
open bossLib Theory Parse res_quanTheory
open fixedPointTheory finite_mapTheory listTheory pairTheory pred_setTheory
open integerTheory set_relationTheory sortingTheory stringTheory wordsTheory

val _ = numLib.prefer_num();



open SemanticPrimitivesTheory ElabTheory AstTheory TokensTheory LibTheory

val _ = new_theory "SmallStep"

(*open Lib*)
(*open Ast*) 
(*open SemanticPrimitives*)

(* Small-step semantics for expression only.  Modules and definitions have
 * big-step semantics only *)

(* Evaluation contexts
 * The hole is denoted by the unit type
 * The env argument contains bindings for the free variables of expressions in
     the context *)
val _ = Hol_datatype `
 ctxt_frame =
    Chandle of unit => varN => exp
  | Capp1 of op => unit => exp
  | Capp2 of op => v => unit
  | Clog of lop => unit => exp
  | Cif of unit => exp => exp
  | Cmat of unit => (pat # exp) list
  | Clet of varN => unit => exp
  (* Evaluating a constructor's arguments
   * The v list should be in reverse order. *)
  | Ccon of conN id => v list => unit => exp list
  | Cuapp of uop => unit`;

val _ = type_abbrev( "ctxt" , ``: ctxt_frame # envE``);

(* State for CEK-style expression evaluation
 * - constructor data
 * - the store
 * - the environment for the free variables of the current expression
 * - the current expression to evaluate, or a value if finished
 * - the context stack (continuation) of what to do once the current expression
 *   is finished.  Each entry has an environment for it's free variables *)
val _ = Hol_datatype `
 exp_or_val =
    Exp of exp
  | Val of v`;


val _ = type_abbrev( "state" , ``: envM # envC # store # envE # exp_or_val # ctxt list``);

val _ = Hol_datatype `
 e_step_result =
    Estep of state
  | Etype_error
  | Estuck`;


(* The semantics are deterministic, and presented functionally instead of
 * relationally for proof rather that readability; the steps are very small: we
 * push individual frames onto the context stack instead of finding a redex in a
 * single step *)

(*val push : envM -> envC -> store -> envE -> exp -> ctxt_frame -> list ctxt -> e_step_result*)
val _ = Define `
 (push envM envC s env e c' cs = (Estep (envM, envC, s, env, Exp e, ((c',env) ::cs))))`;


(*val return : envM -> envC -> store -> envE -> v -> list ctxt -> e_step_result*)
val _ = Define `
 (return envM envC s env v c = (Estep (envM, envC, s, env, Val v, c)))`;


(* apply a context to a value *)
(*val continue : envM -> envC -> store -> v -> list ctxt -> e_step_result*)
val _ = Define `
 (continue envM envC s v cs =  
((case cs of
      [] => Estuck
    | (Chandle ()  n e, env) :: c =>
        return envM envC s env v c
    | (Capp1 op ()  e, env) :: c =>
        push envM envC s env e (Capp2 op v () ) c
    | (Capp2 op v' () , env) :: c =>
        (case do_app s env op v' v of
            SOME (s',env,e) => Estep (envM, envC, s', env, Exp e, c)
          | NONE => Etype_error
        )
    | (Clog l ()  e, env) :: c =>
        (case do_log l v e of
            SOME e => Estep (envM, envC, s, env, Exp e, c)
          | NONE => Etype_error
        )
    | (Cif ()  e1 e2, env) :: c =>
        (case do_if v e1 e2 of
            SOME e => Estep (envM, envC, s, env, Exp e, c)
          | NONE => Etype_error
        )
    | (Cmat ()  [], env) :: c =>
        Estep (envM, envC, s, env, Exp (Raise Bind_error), c)
    | (Cmat ()  ((p,e)::pes), env) :: c =>
        if ALL_DISTINCT (pat_bindings p []) then
          (case pmatch envC s p v env of
              Match_type_error => Etype_error
            | No_match => Estep (envM, envC, s, env, Val v, ((Cmat ()  pes,env) ::c))
            | Match env' => Estep (envM, envC, s, env', Exp e, c)
          )
        else
          Etype_error
    | (Clet n ()  e, env) :: c =>
        Estep (envM, envC, s, bind n v env, Exp e, c)
    | (Ccon n vs ()  [], env) :: c =>
        if do_con_check envC n ( LENGTH vs + 1) then
          return envM envC s env (Conv n ( REVERSE (v ::vs))) c
        else
          Etype_error
    | (Ccon n vs ()  (e::es), env) :: c =>
        if do_con_check envC n ( LENGTH vs + 1 + 1 + LENGTH es) then
          push envM envC s env e (Ccon n (v ::vs) ()  es) c
        else
          Etype_error
    | (Cuapp uop () , env) :: c =>
       (case do_uapp s uop v of
           SOME (s',v') => return envM envC s' env v' c
         | NONE => Etype_error
       )
  )))`;


(* The single step expression evaluator.  Returns None if there is nothing to
 * do, but no type error.  Returns Type_error on encountering free variables,
 * mis-applied (or non-existent) constructors, and when the wrong kind of value
 * if given to a primitive.  Returns Bind_error when no pattern in a match
 * matches the value.  Otherwise it returns the next state *)

(*val e_step : state -> e_step_result*)
val _ = Define `
 (e_step (envM, envC, s, env, ev, c) =  
((case ev of
      Val v  =>
	continue envM envC s v c
    | Exp e =>
        (case e of
            Lit l => return envM envC s env (Litv l) c
          | Raise e =>
              (case c of
                  [] => Estuck
                | ((Chandle ()  n e',env') :: c) =>
                     (case e of
                          Int_error i =>
                           Estep (envM,envC,s,(bind n (Litv (IntLit i)) env'),Exp e',c)
                        | _ => Estep (envM,envC,s,env,Exp (Raise e),c)
                     )
                | _::c => Estep (envM,envC,s,env,Exp (Raise e),c)
              )
          | Handle e n e' =>
              push envM envC s env e (Chandle ()  n e') c
          | Con n es =>
              if do_con_check envC n ( LENGTH es) then
                (case es of
                    [] => return envM envC s env (Conv n []) c
                  | e::es =>
                      push envM envC s env e (Ccon n [] ()  es) c
                )
              else
                Etype_error
          | Var n =>
              (case lookup_var_id n envM env of
                  NONE => Etype_error
                | SOME v => 
                    return envM envC s env v c
              )
          | Fun n e => return envM envC s env (Closure env n e) c
          | App op e1 e2 => push envM envC s env e1 (Capp1 op ()  e2) c
          | Log l e1 e2 => push envM envC s env e1 (Clog l ()  e2) c
          | If e1 e2 e3 => push envM envC s env e1 (Cif ()  e2 e3) c
          | Mat e pes => push envM envC s env e (Cmat ()  pes) c
          | Let n e1 e2 => push envM envC s env e1 (Clet n ()  e2) c
          | Letrec funs e =>
              if ~  ( ALL_DISTINCT ( MAP (\ (x,y,z) . x) funs)) then
                Etype_error
              else
                Estep (envM,envC, s, build_rec_env funs env env, Exp e, c)
          | Uapp uop e =>
              push envM envC s env e (Cuapp uop () ) c
        )
  )))`;


(* Define a semantic function using the steps *)

(*val e_step_reln : state -> state -> bool*)
(*val small_eval : envM -> envC -> store -> envE -> exp -> list ctxt -> store * result v -> bool*)

val _ = Define `
 (e_step_reln st1 st2 =
  (e_step st1 = Estep st2))`;


 val small_eval_def = Define `

(small_eval menv cenv s env e c (s', Rval v) =  
(? env'. ( RTC e_step_reln) (menv,cenv,s,env,Exp e,c) (menv,cenv,s',env',Val v,[])))
/\
(small_eval menv cenv s env e c (s', Rerr (Rraise err)) =  
(? env'. ( RTC e_step_reln) (menv,cenv,s,env,Exp e,c) (menv,cenv,s',env',Exp (Raise err),[])))
/\
(small_eval menv cenv s env e c (s', Rerr Rtype_error) =  
(? env' e' c'.
    ( RTC e_step_reln) (menv,cenv,s,env,Exp e,c) (menv,cenv,s',env',e',c') /\
    (e_step (menv,cenv,s',env',e',c') = Etype_error)))`;


(*val e_diverges : envM -> envC -> store -> envE -> exp -> bool*)
val _ = Define `
 (e_diverges menv cenv s env e =  
(! menv' cenv' s' env' e' c'.
    ( RTC e_step_reln) (menv,cenv,s,env,Exp e,[]) (menv',cenv',s',env', e',c') ==>
    (? menv'' cenv'' s'' env'' e'' c''.
      e_step_reln (menv',cenv',s',env', e',c') (menv'',cenv'',s'',env'',e'',c''))))`;


val _ = export_theory()

