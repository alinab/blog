---
title: "A Brief Introduction to OxCaml Modes"
date: 2026-08-31
tags: [post, oxcaml, fpl]
katex: true
published: true
---

Having recently read through the paper on [OxCaml](https://dl.acm.org/doi/pdf/10.1145/3674642),
the basic idea of modes as qualifiers on types was simple enough to grasp. A
mode is a combination of three axes of qualifiers that determine how many times
a value can be used, if a value has only reference to it and if a value can live
beyond the region it is defined in. It's only after working through the paper
by writing snippets of code and poking at the type system did that rules become
clear. This is the first of two-part post on the paper, so hopefully reading it
is a good introduction to OxCaml's type system, a topic for the post after this.

This entire post is a markdown file with pieces of code interspersed with
explanatory comments. Some of these pieces are as presented in the paper or
their slightly modified versions while others have been generated with the help
Claude. All code presented here have been tested with OxCaml compiler versions
5.2 and 5.4.

## Uniqueness

The paper describes a unique value as one which the type system guarantees
to have only one reference and hence a memory location at which that value can
be replaced by a new one. Section 2.1 shows the following example:

```ocaml
type 'a list = Nil | Cons of { hd : 'a; tl : 'a list }

let rec rev_append xs acc =
  match xs with
  | Nil -> acc
  | Cons x_xs ->
    let tl = x_xs.tl in
    rev_append tl (Cons (overwrite_ x_xs with { tl = acc }))

let reverse xs = rev_append xs Nil
```

Both 5.2 and 5.4 failed to compile the above. For OxCaml 5.2, the error is:

```mdx-error
Error: The overwriting extension is disabled
       To enable it, pass the '-extension overwriting' flag

Alert Translcore: Overwrite not implemented.
Fatal error: exception File "parsing/location.ml", line 1124, characters 2-8: Assertion failed
```

In 5.4:

```mdx-error
Alert Translcore: Overwrite not implemented.
>> Fatal error: Location.todo_overwrite_not_implemented
Fatal error: exception Misc.Fatal_error
```

*If it had been/When it is* implemented, `overwrite_` should replace the
list in the  `tl` of each `Cons` record with `Nil` (at the start of the
`rev_append` function) or the reversed `Cons` record accumulated so far,
thus reusing the same memory location for `x_xs` rather than a new allocation.
This can only be possible when the `xs` is unique; being overwritten does not
affect any other value in the program.

### Parts of Unique types

A pair type is defined as follows:

```ocaml
# type ('a, 'b) pair = { fst : 'a; snd : 'b };;
type ('a, 'b) pair = { fst : 'a; snd : 'b; }
```

The keyword `unique` is used to mark types as unique. Now how would a `pair` type
marked with the `unique` mode behave? Let's look at the following snippet:

```ocaml
let process_unique_pair (pair @ unique) =
  let x @unique = pair.fst in
  let y @unique = pair.fst in

  let repair @unique = {fst = y ; snd = x} in
                                        ^
  This value is used here, but it is already being used as unique

  let x @unique = repair.fst in
  let y @unique = repair.snd in

  Printf.printf "x = %d, y = %d \\n" x y


let _ = process_unique_pair {fst = 5; snd = 8}
```

The OxCaml type checker reports an error (indicated by ^ above). The first `y`
is a binding storing a reference to a `unique` value. In creating the `repair`
record, `fst = y` *uses* up the unique value `pair.fst`. At `snd = x`, the
type-checker figures out that x also refers to the same unique value and
responds that a unique value or reference cannot be used up twice.
Now if we were to replace the first `y` binding as:

```ocaml
let process_unique_pair (pair @ unique) =
  let x @unique = pair.fst in
  let y @unique = pair.snd in

  let repair @unique = {fst = y ; snd = x} in

  let x @unique = repair.fst in
  let y @unique = repair.snd in

  Printf.printf "x = %d, y = %d \\n" x y

let _ = process_unique_pair {fst = 5; snd = 8}

x = 8, y = 5
```

Now there are no complaints from the type-checker. The first `x` and `y` are
bindings to `unique` values and used to construct a new `unique` record
(a fresh allocation in memory) so here we have `repair` as a unique value with
fields containing references to distinct `unique` values. The second set of `x`
and `y` bindings shadow the first and flipped values get printed at the end.

Adding a second record construction without `unique` modes on the first as:

```ocaml
let process_unique_pair (pair @ unique) =
  let x @unique = pair.fst in
  let y @unique = pair.snd in

  let repair = {fst = y ; snd = x} in

  let x = repair.fst in
  let y = repair.fst in

  let repair' = {fst = x ; snd = y} in
                                 ^
  This value is used here, but it is already being used as unique

  let x @ unique = repair'.fst in
  let y @ unique = repair'.fst in

  Printf.printf "x = %d, y = %d total: %d \\n" x y (x + y)

let _ = process_unique_pair {fst = 5; snd = 8}

```

The type-checker complains that in constructing `repair'`, `y` is being
*reused* even though both `repair` and `y = repair.fst` are
*not marked as unique*. Starting from the `pair @ unique` type input to
`process_unique_pair`, the type-checker traces that `repair.fst` is `pair.snd`,
a `unique` value, and the second set of `x` and `y` are two different bindings
referring to one unique value and so cannot be reused to construct `repair'`.

### Uniqueness of a list

The return type of the `rev_append` function is annotated with
`unique`. The function reverses the list by consing elements starting with an
empty list.

```ocaml
# let rec rev_append xs acc : _ list @ unique =
    match xs with
    | [] -> acc
    | (x :: rest) -> rev_append rest (x :: acc);;
val rev_append : 'a list @ unique -> 'a list @ unique -> 'a list @ unique =
  <fun>

# let rev_list @ unique = rev_append [4;6;8;2;19] [];;
val rev_list : int list = [19; 2; 8; 6; 4]
```

### Aliased parts of a unique pair

The mode that marks a value as *not unique* is `@aliased` and shown in the
following snippet:

```ocaml
# let process_parts_aliased (pair @ unique) =
    let x @aliased = pair.fst in
    let y @aliased = pair.fst in
    Printf.printf "Aliased: x = %d, y = %d\\n" x y

  let _ = process_parts_aliased {fst = 5; snd = 8}

  Aliased: x = 5, y = 5\n
```

The same `unique` value has been assigned to two different variables `x` and
`y`, both marked as `aliased` meaning values which may have more than one reference.
`x` and `y` both refer to `pair.fst` which is `unique`. But a *`sub-moding`*
relation between `aliased` and `unique` allows `unique` values to be used as
`aliased` which makes `pair.fst` *not unique* within the function and permits
two references to it.

Taking an earlier example, `repair`'s `fst` field is used to create two unique
values:

```ocaml
let process_unique_pair (pair @ unique) =
  let x @unique = pair.fst in
  let y @unique = pair.snd in

  let repair @unique = {fst = y ; snd = x} in

  let x @unique = repair.fst in
  let y @unique = repair.fst in

  Printf.printf "x = %d, y = %d total = %d \\n" x y (x + y)

let _ = process_unique_pair {fst = 5; snd = 8}

x = 8, y = 8 total = 16
```

The second set of `x` and `y` end up as bindings to the same `unique` value.
Why does then this piece pass the type-checker?  The only explanation is that
the second set of `x` and `y` are being used as `aliased` values.

When types are not explicitly marked `unique`, they are marked as `aliased`
by default. In the piece below,`x`, `y`, `z` and `z'` are treated as `aliased`
values as:

```ocaml
let process_parts_pair (pair @ unique) =
  let x = pair.fst in
  let y = pair.snd in

  let z =  x in
  let z' = y in

  Printf.printf "Test: x = %d, y = %d\\n" x y;
  Printf.printf "Test: z = %d, z' = %d\\n" z z'

let _ = process_parts_pair {fst = 11; snd = 22}

x = 11, y = 22\n
z = 11, z' = 22\n
```

Both `z` and `z'` are references t `aliased` values `x` and `y`. So using `x`
and `y` twice, once directly in the first `printf` statement and the second time
via `z`, `z'` is possible. Modifying the function into:

```ocaml
let process_parts_pair (pair @ unique) =
  let x = pair.fst in
  let y = pair.snd in

  let z = x in
  let z' = y in

  process_unique_pair pair;

  Printf.printf "Test: x = %d, y = %d\\n" x y;
                                            ^
  Error: This value is used here,
       but it is part of a value that has already been used as unique

  Printf.printf "Test: x = %d, y = %d\\n" z z'

let _ = process_parts_pair {fst = 11; snd = 22}
```

The type error comes up because after `process_unique_pair` is
called using the `unique` input `pair`, the `unique` components of `pair`,
 `pair.fst` and `pair.fst` are used. The type-checker determines that the
components of a `unique` value has already been used and the associated aliased
references, `x`, `y` referring to those same unique values cannot be used.

## Affinity for Closures

Closures are ubiquitous in functional programming. They are functions that
capture values from the lexical region around them. Capturing a value stores
it in the closure.

```ocaml
let with_unrestricted_closures =
  let xs : int list @ unique = [1;2;3;4;5] in
  let f = fun zs -> rev_append xs zs in
  let ys @ unique = f [6] in
  let zs @ unique = f [7] in

 print_endline "";
 List.iter (fun x -> Printf.printf "%d " x) ys;

 print_endline "";
 List.iter (fun x -> Printf.printf "%d " x) zs
```

```mdx-error
Error: This value is used here,
       but it is defined as once and has already been used:
File "...", line 9, characters 20-21:
9 |   let ys @ unique = f [6] in
```

In `with_unrestricted_closure`, closure `f` captures a value of `list @unique`
type and returns a `unique` reversed list. The two calls to `f` mean using the
same `unique` value twice. The error is pointing to the inferred mode for `f`
which is `@once`:

```ocaml
  let f @ once = fun zs -> rev_append xs zs in ...
```

The type-checker is hinting that closures that capture `unique` values can only
be called `@once`. The mode determining the number of times a function or
closure can be called is called affinity. An affine value can be called at most
once.

```ocaml
# let with_restricted_closure =
    let xs_1: int list @ unique = [1;2;3;4;5] in
    let xs_2 : int list @ unique = [1;2;3;4;5] in
    let f = fun ls -> rev_append xs_1 ls in
    let ys = f [6] in
    Printf.printf "\\n";
    List.iter (fun x -> Printf.printf "%d " x) ys;
    let g @ once = fun ls -> rev_append xs_2 ls in
    let zs = g [7] in
    Printf.printf "\\n";
    List.iter (fun x -> Printf.printf "%d " x) zs;;

5 4 3 2 1 6
5 4 3 2 1 7
```

`with_restricted_closure` works by giving each closure (`f`, `g`) its own
unique list to capture; `g` is marked with `@ once` to make explicit that it may
only be called only one time.

The paper makes the following statements:

> Unlike with uniqueness, affinity cannot be forgotten. Uniqueness is a
> statement about the past (a value has not been aliased); it is safe to
> forget this detail. In contrast, affinity is a statement about the future
> (a value cannot be aliased); forgetting it could potentially make memory reuse
> observable

A value that is currently `unique` only has one reference and using it as an
`aliased` value does not affect it's underlying mode. A value's affinity is a
guarantee about how it will be used in the future.

The sub-moding for affinity is `many < once` i.e. values or types marked `many`
can be used `once` but a `once` value can never be used `many` times. With
`unique < aliased`, the unique value can "forget" its uniqueness and be used as
a value with possibly more than one reference. But a `once` affinity can never be
forgotten because if it were, the sub-moding relation would be `once < many` -
closures that capture `unique` values could be called repeatedly thus clashing
with the restriction on the reuse of `unique` values.

## A list type with aliased elements

The paper defines modes as deep wherein the elements constituting type with
a mode also have that same mode. But if this restriction were to be eased up,
then for example, an`'a list` can give the list itself and its elements
different modes.

```ocaml
# type 'a list_with_aliased_elts =
    Nil
    | Cons of { hd : 'a @@ aliased;
                tl : 'a list_with_aliased_elts };;

type 'a list_with_aliased_elts =
    Nil
  | Cons of { hd : 'a @@ aliased; tl : 'a list_with_aliased_elts; }
```

`a_list_with_aliased_elts` type marks `hd` with the `@@ aliased` field modality.
The list itself can be `@ unique` while each element is `@ aliased`

The paper describes a type:

```ocaml
val graph_nodes : graph -> node aliased list @ unique
```

Fleshing out this type and related code is very helpful in seeing how a
`unique` list with `aliased` nodes can result.

NOTE: The OxCaml Stdlib provides a `Modes.Aliased.t` wrapper that pins a
value to `aliased` mode. Wrapping the element type lets us use a plain `'a list`
(and standard functions `List.map`/`List.iter`) instead of a custom type.

```ocaml
module Aliased : sig
  type 'a t = { aliased : 'a @@ aliased } [@@unboxed]
end
```

In the type definition above, the `[@@unboxed]` attribute tells the compiler to
not put the type in a box or allocate a separate block on the heap to store the
type. By definition, this is only possible for types which have only one
constructor with one argument or a record with one field.

```ocaml
type node = { id : int;
              mutable neighbors : int list }

type graph = { nodes : node array }

let graph_nodes (g : graph) : node Modes.Aliased.t list @ unique =
  let rec loop i =
    if i >= Array.length g.nodes
    then []
    else
      { Modes.Aliased.aliased = g.nodes.(i) } :: loop (i + 1)
  in
  loop 0

let () =
  let g =
     { nodes =
        [| { id = 1; neighbors = [ 2; 3 ] }
         ; { id = 2; neighbors = [ 1 ; 3; 4] }
         ; { id = 3; neighbors = [ 1; 2; 4] }
         ; { id = 4; neighbors = [ 2 ; 3] }
        |]
    }
  in
  let ns @ unique = graph_nodes g in
  List.iter (fun (w : node Modes.Aliased.t) ->
      Printf.printf "\\n node: %d " w.aliased.id) ns;
      Printf.printf "\\n graph still has %d nodes\\n" (Array.length g.nodes)
```

Here the `node` type is annotated with `Modes.Aliased.t`. The `unique` list
resulting from calling `graph_nodes` is itself unique even when it contains
`aliased` nodes. Iterating through the list does not use up its values.

```ocaml
let rev_graph_nodes graph =
  let aliased_nodes @ unique = graph_nodes graph in
  let nodes : int list @ aliased =
     List.map (fun (w : node Modes.Aliased.t) -> w.aliased.id) aliased_nodes in
  let rev_nodes = List.rev nodes in
    Printf.printf "Nodes for the reversed graph:\\n";
    List.iter (fun x -> Printf.printf "%d " x) rev_nodes

let () =
  let g =
    { nodes =
        [| { id = 1; neighbors = [ 2; 3 ] }
         ; { id = 2; neighbors = [ 1 ; 3; 4] }
         ; { id = 3; neighbors = [ 1; 2; 4] }
         ; { id = 4; neighbors = [ 2 ; 3] }
        |]
    }
  in
  rev_graph_nodes g
```

With `aliased_nodes` as the `@unique` input, the `nodes` function maps the `id`s
of `aliased` nodes and returns a list that is `aliased` because a list that does
not contain explicitly `unique` values is `aliased`. This is a reversal of how
`unique` values can be used as `aliased` or a `unique` constructor can contain
individually `aliased` values. But a `list` constructed by iterating over a list
of `unique` values cannot be `unique` itself.

## Locality

Another mode specification is locality which constrains values from leaving a
region. The definition of a region is OCaml is important to understand before
moving on.

Functional languages such as Haskell have a function named
`main` that is the function from which execution begins. In OCaml, there is no
such restriction. OCaml programs are laid out as a sequence of `let` bindings
with those at the first or top level of the file being global bindings and
others being local to the function within which they are defined.

The body of a function (created by a `let` binding) is a region. Creating the
following function results in:

```ocaml
let bad () = let xs @ local = [1;2;3] in xs
```

```mdx-error
Error: This value is "local"
       but is expected to be "local" to the parent region or "global"
       because it is a function return value.
       Hint: Use exclave_ to return a local value.
```

`let xs @ local =` creates a local region. All values should remain within
it but here, the list escapes to the outer region for the `bad ()` function.

Rewriting the above removes the type error:

```ocaml
# let rec length_local (xs : 'a list @ local) : int =
    match xs with
    | [] -> 0
    | _ :: tl -> 1 + length_local tl;;
val length_local : 'a list @ local -> int = <fun>
```

```ocaml
# let good () = let xs : int list @local = [1;2;3] in
        let n = length_local xs in n;;
val good : unit -> int = <fun>
```

(Note: In 5.2 and 5.4, `List.length` is not mode-polymorphic
(`val length : 'a list -> int`, no `@ local`), so it can't take a
`local` list at all. This is why the `length_local` function has been
added).

## Borrowing and a `sneaky` attempt

Taking the idea from the Rust programming language, the `borrow_`
constructor is used to write a `borrow` function where a `unique` value
is copied locally, passed to `f` and a tuple result with the original
`unique` value and the result of the local copy of `x` applied to `f`.
Since the borrow creates a `local` value, after `f` returns or the
region of the `let result = f (borrow_ (x : 'a @ local))` function no
longer exists, only one reference to the `x : 'a unique` remains.

The `&x` in the paper apparently stands for the actual `borrow_` construct.

```ocaml
type 'a global = { g : 'a @@ global }
type 'a aliased = { a : 'a @@ aliased }

let borrow x f = let result = f (borrow_ (x : 'a @ local))
      in (x : 'a @ unique), { a = result }

```

```ocaml
let sneaky : int list @ unique -> (int list * int list aliased) @ unique =
  fun xs ->
    let global_xs : int list global @ unique = { g = xs } in
    let { g = ys}, { a = ys' } =
      borrow global_xs (fun { g = xs' } -> xs') in
    ys, { a = ys' }
```

The provided snippet does not type check for 5.2 but does return the following
error for 5.4:

```mdx-error
Error: This value is aliased
         because it is the field g (with some modality) of the record at file "sneaky.ml", line 10, characters 8-18.
       However, the highlighted expression is expected to be unique
         because it is an element of the tuple at file "sneaky.ml", line 12, characters 4-19
         which is expected to be unique.
```

`xs` is a `unique` value. The borrow construct copies `xs` to `ys`. The field g
is `global` (the `global` before the `@unique`) and so `aliased` by definition.
This means it is not guaranteed to be `unique`, even though the entire record is
marked as `unique`. Since the value of `g` cannot be both `unique` and
`aliased`, the error crops up.

## Modes

All of the examples shown until now involve modes where a mode `μ` is a triple
`(a,u,l)` with an affinity `a`, a uniqueness `u` and a locality `l`.

```
(modes)         μ ::= (a, u, l)
(affinities)    a ::= many | once
(uniquenesses)  u ::= unique | aliased
(localities)    l ::= global | local
```

Each mode axis has an order among its two constituent elements with:

 `many < once` `unique < aliased` `global < local`

When a mode element `μ ≤ μ'`, a term at mode`μ` can always be used where `μ'` is
expected but never the other way around. This relation had been described as
*sub-moding* and has already been used to construct correct code in the examples
shown in the previous sections.

The paper describes `modes are ordered pointwise` i.e. the entire mode is
determined by the triple made up of combining the determined order of three
axes. For `μ ≤ μ'` to be valid, the conjunction of `a ≤ a'` and `u ≤ u'` and
`l ≤ l'`  must be valid.

Some type-qualifier systems (like Walker's) attach qualifiers to *every* type,
including value types nested inside pairs and records. A working
version of such a system with linear types is documented
[here](https://github.com/alinab/attpl/blob/main/lincheck.ml). Such systems
needs additional checks (see `containment_check` at the above link) to make sure
that side conditions in rules for type formation with qualified types are met.

OxCaml's calculus adds qualifiers only to *computation* types. Since value types
do not have any qualifiers or modes, in order to modify parts of data structures
to have a mode different from the mode for the entire structure - an `aliased`
field inside an otherwise`unique` record for example — the calculus introduces a
**box type** `□^ν τ` to represent the **modality** `ν`. Taking the box as the
structure with a mode, the mode of the box's content along one or more axes is
described by modalities acting on mode triples to describe or determine these axes.

The three modalities A, M and G are:

```ocaml
A(a, u, l) = (a, aliased, l)
M(a, u, l) = (many, u, l)
G(a, u, l) = (a, aliased, global)
```

The `A` or (`@@aliased`) modality forces uniqueness to `aliased`. The `M` or
(`@@many`) forces affinity to `many` and the `G` modality forces *both*
uniqueness to `aliased` and locality to `global`. In the `borrow` construct, in
order to copy a `unique` value to a `local` value, it is imperative to ensure
that the value to be copied cannot be `global` as a `'a global` makes the value
silently default to `aliased`. In sneaky, xs is
deliberately wrapped in the 'a global type before being borrowed and that is why
it fails.

In OxCaml syntax, all three modalities show up as `@@`-tagged, `[@@unboxed]`
wrapper records — the same shapes already used earlier in this post:

```ocaml
type 'a aliased = { a : 'a @@ aliased } [@@unboxed]
type 'a many    = { m : 'a @@ many }    [@@unboxed]
type 'a global  = { g : 'a @@ global }  [@@unboxed]
```

The `[@@unboxed]` attribute used when defining a type has zero allocation at
runtime since each type, `'a aliased`, `'a many`, `'a global` is a
record with exactly one field, a narrower case from the definition described in
the `graph_nodes` section.

### §3.2 Syntax

Let's go over the syntax of the mode calculus.

Contexts are *ordered* lists of bindings, each binding
either giving a variable a type and mode, or marking it unusable once
it's been consumed (`Γ, x : −`):

```ocaml
Γ ::= ∅ | Γ, x : − | Γ, x : τ @ μ
```

Types consist of the unit type, sums, products, the
box type from §3.1, a function type that records the mode of *both*
its argument and its result (`τ @ μ → τ @ μ`), and a type for
*space credits*, `♣`, for in-place memory reuse:

```ocaml
τ ::= 1 | τ + τ | τ × τ | □^ν τ | τ @ μ → τ @ μ | ♣
```

The expression language is:

```ocaml
e ::= x | ()
      | inl e | inr e | (e, e)
      | λx. e | e e
      | let x = e in e
      | box_ν e | unbox_ν e
      | let (x, y, z) = e in e
      | case e { inl x → e; inr y → e }
      | reuse e in (e, e)
      | borrow x = e for y = e in e
```

`x`, `()`, `inl e`, `inr e`, `(e, e)`, `λx. e`, `e e`, `let x = e in e`,
`case e { inl x → e; inr y → e }` are standard functional programming
syntax for variables, unit and pairs, abstractions, applications, let bindings
and pattern matching via case. `box_ν e` introduces the modality `ν` in `e`
and `unbox_ν` eliminates the same from `e`.

`let (x, y, z) = e in e` destructures a
pair `e` into `y` and `z` *and* hands back the pair's own *space credit* `x`.
If the allocation for `x` is `unique`, it can be later spent by
`reuse x in (e, e)` to allocate a fresh pair without a new allocation.
`borrow x = e1 for y = e2 in e3` is the formal core behind the
`borrow`/`borrow_` constructs used in earlier examples. The paper doesn't give
stack-allocated regions their own separate syntax at all; a region is just
`borrow _ = () for y = e1 in e2` with `e1` bound in a fresh region denoted
by `e2`.

## Acknowledgements and the Next Post: Type rules and Inference

I hope this write-up has been a gradual and easy introduction to modes in
OxCaml. For cleaning up text, generating code pieces and checking the final
draft for errors, Claude's help was very useful.

I hope to have the next post on the OxCaml type system and type inference up soon.
