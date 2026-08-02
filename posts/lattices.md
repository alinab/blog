---
title: "Bounds for Ordered Sets"
date: 2026-08-01
tags: [post, fpl]
katex: true
published: true
---

The essential idea from [the previous post on orders](../posts/order.html) is that
comparing the
elements of a set gives rise to relations between them and adding a "sense" (a
measure that quantifies the relation mathematically) to the relation allows for
the ordering of elements within the set. Taking only those ordered sets where
elements can be related to themselves (irreflexive) and where not every element
is related to another in the set (partial), taking subsets of such posets and
checking if any notable properties emerge from them is interesting exercise, so
let's start there.

### Subsets of ordered sets

Take a subset $Y$ of an partially ordered set $X$ with relation $R$ on it. In $X$:

- a ***lower bound*** is an element $x$ where $x R y, \forall y \in Y$
(x bounds Y from below)
- an ***upper bound*** is an element $x$ where $y R x, \forall y \in Y$
(x bounds Y from above)

![](/assets/images/upper_lower_bound_sets.svg)

The set of all lower bounds is defined as:

<div align="center">
$$Y^{\ell} = \{ x \in X \mid (\forall y \in Y)\ x R y \}$$
(the set of all values in X that bound the subset Y from below)
</div>

and the set of all upper bounds as:

<div align="center">
$$Y^u =  \{x \in X | (\forall y \in Y) y R x \}$$
</div>

(the set of all values in X that bound the subset Y from above)

![](/assets/images/upper_lower_bound_sets_multi.svg)

Note that all of these arises from nothing more than taking a subset of the
original partially set and using the relation $R$ to relate members of the
original set $X$ and the subsets $Y$. Because $X$ is an *ordered set* using
a *binary* relation $R$, the sets of bounds are also ordered in two
directions - lower and upper.

When the set of upper bounds Y$^u$ has a least element, it is the ***least
upper bound*** of $Y$ which is given by $x$:

 $$(\forall x' \in X [((\forall y \in Y) y R x' \iff x R x')])$$

Considering the dual, the set of lower bounds Y$^l$ has a greatest element or the
***greatest lower bound*** and is given by $x$:

 $$(\forall x' \in X [((\forall y \in Y) x' R y \iff x' R x)])$$

In literature, the least upper bound is the ***supremum*** (written as sup $Y$)
of the subset $Y$ and the greatest lower bound is the ***infimum*** of Y\
(written as inf $Y$)

![](/assets/images/lub_glb_diagram.svg)

Important points to note are:

- A set Y need not have a supremum or an infimum.

    - E.g. Let X = {a, b, c, d} be a poset with:

      $R = \{a, c\}, \{a, d\}, \{b, c\}, \{b, d\}$ (neither c R d nor d R c holds).

    Take Y = {a, b}. To calculate the set of upper bounds for Y, $x \in X$
    must be $y R x$ i.e. for each $y \in Y$:

    | y    | relation |x|
    | ---- | ----- | ---|
    | a    | a R c | c  |
    | a    | a R d | d  |
    | b    | b R c | c  |
    | b    | b R d | d  |

    S^u = {c, d}

    To get only one element out of $S^u$ requires a comparision between c and d
    but since R does not hold for both, there's no least element or supremum in
    {c, d}.


- A supremum or an infimum, if either exist, are always unique. Looking at the
definition above, if x and x' are both upper bounds in $X$, then we must have
$x R x'$ **and** $x' R x$ which is only possible when x' = x in a poset (the
antisymmetry property).

- The supremum or the infimum of a set may or may not belong to the set itself.
    - The closed interval [0, 1] of reals has a sup of 1 which is contained in
    the set itself.
    - The open interval (0, 1) of reals again has a sup of 1 but this is not
    contained within the set {0,1}.

An poset X has a bottom element if there exists $\bot \in X$ (called
bottom) with the property that $\bot R x$ for all  x $\in X$. The dual
element in X is a top element which if exists is defined as $x R \top$
for all $x \in x$. For the set of upper bounds Y$^u$, the least upper
bound or supremum $= \top$ and the set of lower bounds Y$_u$, the
greatest lower bound or infimum $= \bot$.

### Lattices

So far, the definitions of subsets of posets have meant any subset of a
poset $X$. Now if the definition were to narrowed down to every two-element
(or doubleton) subset of $X$, then a structure called a **
*lattice emerges from $X$ only if***:

- $\forall x, y \in X$, the least upper bound exists. This is called
a ***join*** and denoted by $x \vee y$
- $\forall x, y \in X$, the greatest upper bound exists. This is called
a ***meet*** and denoted by $x \wedge y$

A poset $X$ is a join-semilattice (or upper-semilattice) in which
$\forall x, y \in X$, $x \vee y$ exists. The dual holds for meet-s
semilattices (lower-semilattices) i.e. $\forall x, y \in X$,
$x \wedge y$.

For a subsets $S \subseteq X$:

- $\bigvee S$ is the least upper bound or join of subset $S$
- $\bigwedge S$ is the greatest lower bound or meet of subset $S$

If both $\bigvee S$, $\bigwedge S$ exist for all $S \subseteq X$, the
$X$ is a complete lattice.

#####  Filters
A principal filter or principal up-set on a poset $X$ generated by an
element $y$ is defined as:

$$\uparrow y = \{ z \in X | y R z \}$$

$\uparrow y$ is everything in the poset that is "at" or "above" y
(at because y R y by definition).

The set of upper bounds of two element set, $\{x, y\}^{u} is given by
$\uparrow y$ since x R y, nothing "below" $Y$ can be an upper bound.
Since the least element of $\uparrow y$ is y, $x \vee y = y$.

A principal down-set on a poset $X$ generated by an element $z$ is defined as:

$$\downarrow x = \{ z \in X | x R z \}$$

$\downarrow x$ is everything in the poset that is "at" or "below" x (at
because again x R x by definition).

The set of lower bounds of two element set, $\{x, y\}^{l}$ is given by
$\downarrow x$ as nothing "below" x can be a lower bound. Since the least
element of $\downarrow x is x, $x \wedge x = x$.

![](/assets/images/up_down_sets_diagram.svg)

### Hasse diagrams

This far, diagrams for definitions have shown abstract versions of
posets, their subsets, upper/lower bounds. One representation of
specific posets are Hasse diagrams. A Hasse diagram for a poset $X$
with $x, y \in X$ is done as follows:

1. Each $x \in X$ is represented by a small circle.
2. For each pair x $\lessdot$ y (***y covers x*** i.e. y immediately
succeeds x when ordered using $R$), a line from x to y is drawn
3. 1. and 2. must adhere to the following:

    - when x $R$ y, the circle depicting x is lower than the one\
    depicting y
    - the lines joining circles may cross each other but the circles
    depicting elements much never intersect lines.

![](/assets/images/general_poset_letters.svg)

This Hasse diagram is a representation of poset $X = \{(a, d), (b, e),
(b, d), (b, f), (c, f), (c, g), (d, h), (e, h), (e, i), (f, i), (g, i)\}$

Moving upward from an circle depicting an element shows the transitive
relations e.g. b R e R h $\implies$ b R h. Elements e and d are not
ordered by $R$ ($d \hspace{0.2em}|| \hspace{0.2em} e$). The reflexivity
of elements is implied.

### Lattices as an Algebraic Structure

A mathematical or a computational entity has an algebraic structure
when it is comprised of:

- a set of elements
- a finite collection of operations on its elements
- and a finite set of identities (axioms) which hold for all possible
elements of the structure.

Sets themselves have identities that any set must follow. As ordered
sets with other features, lattices are algebraic structures too,a
denoted by $⟨L; \vee, \wedge⟩$

The following rules are equivalent for all lattices from poset $X$,
where $x, y\in X$:

1. x R y
2. x $\vee$ y = y
3. x $\wedge$ y = x

and give rise to the following axioms with $x, y, z \in X$:

- (x $\vee$ y) $\vee$ z = x $\vee$ (y $\vee$ z) (associative)
- x $\vee$ y = y $\wedge$ x (commutative)
- x $\vee$ x = x (idempotency)
- x $\vee$ (x $\wedge$ y)= x (absorption)

The four axioms hold for their dual versions where $\vee$ and $\wedge$
are exchanged.

### Next

Chapter 2 of the [Lattices and Order]((https://paperpile.com/shared/sYA9j_dWBRk6w9lI5zo8G7Q)) has far more details on the topic
of lattices if you are interested. A thorough understanding of these
definitions should, hopefully, be enough to dig through how a lattice
structure has been added to OCaml's type system to build OxCaml in the
next post.

It's thanks to Claude credits that I could come up with the illustrative
diagrams very easily.
