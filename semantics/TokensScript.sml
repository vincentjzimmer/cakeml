(*Generated by Lem from tokens.lem.*)
open bossLib Theory Parse res_quanTheory
open fixedPointTheory finite_mapTheory listTheory pairTheory pred_setTheory
open integerTheory set_relationTheory sortingTheory stringTheory wordsTheory

val _ = numLib.prefer_num();



open LibTheory

val _ = new_theory "Tokens"

(* Tokens for Standard ML.  NB, not all of them are used in CakeML *)
val _ = Hol_datatype `
 token =
  WhitespaceT of num | NewlineT | LexErrorT
| HashT | LparT | RparT | StarT | CommaT | ArrowT | DotsT | ColonT | SealT
| SemicolonT | EqualsT | DarrowT | LbrackT | RbrackT | UnderbarT | LbraceT
| BarT | RbraceT | AbstypeT | AndT | AndalsoT | AsT | CaseT | DatatypeT | DoT
| ElseT | EndT | EqtypeT | ExceptionT | FnT | FunT | FunctorT | HandleT | IfT
| InT | IncludeT | InfixT | InfixrT | LetT | LocalT | NonfixT | OfT | OpT
| OpenT | OrelseT | RaiseT | RecT | SharingT | SigT | SignatureT | StructT
| StructureT | ThenT | TypeT | ValT | WhereT | WhileT | WithT | WithtypeT
| ZeroT
| DigitT of string
| NumericT of string
| IntT of int
| HexintT of string
| WordT of string
| HexwordT of string
| RealT of string
| StringT of string
| CharT of string
| TyvarT of string
| AlphaT of string
| SymbolT of string
| LongidT of string`;

val _ = export_theory()

