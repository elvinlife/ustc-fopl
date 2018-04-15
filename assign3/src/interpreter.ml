open Core
open Ast.IR

exception RuntimeError of string
exception Unimplemented

type outcome =
  | Step of Term.t
  | Val
  | Err of string

(* You will implement the cases below. See the dynamics section
   for a specification on how the small step semantics should work. *)
let rec trystep (t : Term.t) : outcome =
  match t with
  | Term.Var _ -> raise (RuntimeError "Unreachable")

  | (Term.Lam _ | Term.Int _) -> Val

  | Term.TLam (_, t) -> Step t

  | Term.TApp (t, _) -> Step t

  | Term.TPack (_, t, _) -> Step t

  | Term.TUnpack (_, x, t1, t2) -> Step (Term.substitute x t1 t2)

  | Term.App (fn, arg) -> (
      match trystep fn with
      | Val -> (
          match trystep arg with
          | Val -> (
            match fn with
              | Term.Lam(x, t, term)->(
                Step (Term.substitute x arg term)
                )
              | _ -> raise (RuntimeError "Unreachable")
            )
          | Err e -> Err e
        )
      | Step fn' -> Step(Term.App(fn', arg))
      | Err e -> Err e
    ) 

  | Term.Binop (b, t1, t2) -> (
    match trystep t1 with
      | Val -> (
          match trystep t2 with 
          | Val ->(
              match (t1, t2) with
              | (Term.Int i1, Term.Int i2)->(
                match b with
                  | Ast.Add -> Step(Term.Int (i1+i2))
                  | Ast.Sub -> Step(Term.Int (i1-i2))
                  | Ast.Mul -> Step(Term.Int (i1*i2))
                  | Ast.Div -> (
                    if i2 = 0 then Err "divide by zero"
                    else Step(Term.Int(i1/i2))
                    )
                  | _ -> raise (RuntimeError "Unreachable")
                )
            )
          | Step t2' -> Step(Term.Binop(b, t1, t2'))
          | Err e -> Err e
        )
      | Step t1' -> Step(Term.Binop(b, t1', t2))
      | Err e -> Err e
    ) 

  | Term.Tuple (t1, t2) -> (
    match trystep t1 with
      | Step t1' -> (
        match trystep t2 with
          | Step t2' -> Step(Term.Tuple(t1', t2'))
          | Val -> Step(Term.Tuple(t1', t2))
          | Err e -> Err e
        )
      | Val -> (
        match trystep t2 with
          | Step t2' -> Step(Term.Tuple(t1, t2'))
          | Val -> Val
          | Err e -> Err e
        ) 
      | Err e -> Err e
    )

  | Term.Project (t, dir) ->(
      match trystep t with
      | Step t' -> (
        match t' with
          | Term.Tuple(t1, t2) ->(
              match dir with
              | Ast.Left -> Step t1
              | Ast.Right -> Step t2
              | _ -> raise (RuntimeError "Unreachable")
            )
        )
      | Val -> (
        match t with
          | Term.Tuple(t1, t2) ->(
            match dir with
              | Ast.Left -> Step t1
              | Ast.Right -> Step t2
              | _ ->  raise(RuntimeError "Unreachable")
            )
        )
      | Err e -> Err e 
    )

  | Term.Inject (t, dir, tau) ->(
      match trystep t with
      | Val -> Val
      | Step t' -> Step (Term.Inject (t', dir, tau))
      | Err e -> Err e
    ) 

  | Term.Case (t, (x1, t1), (x2, t2)) ->(
      match trystep t with
      | Step t' -> Step(Term.Case (t', (x1, t1), (x2, t2)))
      | Val -> (
          match t with
          | Term.Inject (t', dir, tau) -> (
              match dir with
              | Ast.Left -> Step(Term.substitute x1 t' t1)
              | Ast.Right -> Step(Term.substitute x2 t' t2)
              | _ -> raise(RuntimeError "Unreachable")
            )
          | _ -> raise (RuntimeError "Unreachable")
        )
      | Err e -> Err e
    ) 

let rec eval e =
  match trystep e with
  | Step e' -> eval e'
  | Val -> Ok e
  | Err s -> Error s

let inline_tests () =
  (* Typecheck Inject *)
  let inj =
    Term.Inject(Term.Int 5, Ast.Left, Type.Sum(Type.Int, Type.Int))
  in
  assert (trystep inj = Val);

  (* Typechecks Tuple *)
  let tuple =
    Term.Tuple(((Int 3), (Int 4)))
  in
  assert (trystep tuple = Val);

  (* Typechecks Case *)
  let inj =
    Term.Inject(Term.Int 5, Ast.Left, Type.Sum(Type.Int, Type.Product(Type.Int, Type.Int)))
  in
  let case1 = ("case1", Term.Int 8)
  in
  let case2 = ("case2", Term.Int 0)
  in
  let switch = Term.Case(inj, case1, case2)
  in
  assert (trystep switch = Step(Term.Int 8));

  (* Inline Tests from Assignment 3 *)
  let t1 = Term.Binop(Ast.Add, Term.Int 2, Term.Int 3) in
  assert (trystep t1 = Step(Term.Int 5));

  let t2 = Term.App(Term.Lam("x", Type.Int, Term.Var "x"), Term.Int 3) in
  assert (trystep t2 = Step(Term.Int 3));

  let t3 = Term.Binop(Ast.Div, Term.Int 3, Term.Int 0) in
  assert (match trystep t3 with Err _ -> true | _ -> false)

(* let () = inline_tests () *)
