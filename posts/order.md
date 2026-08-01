---
title: "Putting Everything in Order"
date: 2026-07-31
tags: [post, fpl]
katex: true
published: true
---


A paper I have been reading through on recently ([OxCaml](https://dl.acm.org/doi/10.1145/3674642))
does some very clever things with the OCaml type system. The basic idea is to
wrap OCaml function types with qualifiers to ensure memory access safety
statically from within the type system.

I wanted to write down notes on parts of the paper but then thought of a different
idea - start with the underlying structure that has been used to add qualifiers
to the type system and go from there. And for that, I thought I would start,
as much as possible, from the beginning with relations and orders.

#### The Basics - Relations

To understand what a relation is, let's start with a set. Relying on the definition
of a set to be a collection of objects, a relation can be thought of as a:

- function between sets, for example:

    - *A* as a set of numbers from 1 to 26 and
    - *B* as the set of all letters in the English alphabet,
    - the relation "is the nth letter in the alphabet" written as a function:
    $f(x) = y$ where $x \in A$ and $y \in B$

- sets of elements, where:

    - taking *A* as a set of numbers from 1 to 26 and
    - *B* as the set of all letters in the English alphabet,
    - the relation "is the nth letter in the alphabet" is denoted by R and consists
    of the set of pairs defined as: $(x, y) \in R$ where $x \in A$ and $y \in B$.


Using the second definition, for any two sets *X* and *Y*, denoting *X* x *Y*
as the set of all possible pairs with $x \in X$, $y \in Y$, a binary relation
**R** is its subset i.e. the set containing pairs for **R** holds for $x,y$.
When both $x, y \in X$, **R** is a relation on X itself.

##### Properties of Relations


Using the notation $xRy$ for $(x,y) \in R$, relations on a set X for all
$x,y,z \in X$ can be characterized as:

| Type          | Notation        | Note |
| :------------- | :---------------- | :-------- |
| empty         | $\neg(xRy)$     | $\neg$ denotes negation; in an empty set, no relation can hold |
| reflexive     | $xRx$           |                               |
| irreflexive   | $\neg(xRx$)     |                               |
| identity      | $xRy \to x = y$    |                            |
| transitive    | $xRy \land yRz \to xRz$| $\land$ denotes $and$  |
| symmetric     | $xRy \to yRx$   |                               |
| antisymmetric | $xRy \land yRx \to x=y$ |                       |
| asymmetric    | $xRy \to \neg(yRx)$     |                       |
<!-- | clique        | $xRy$                   | R holds for all $x,y \in X$ | -->

It always helps to work through examples for dry mathematical definitions, so
let's see some for each property listed above. Given $x,y,z \in$ a set $X$:

- **empty** ($\neg(xRy))$:

    - R = $\varnothing$ and $X = {1,2,3,4,5}$ denotes R has no pairs. All of the
    other properties become vacuously true (hold for the empty set) except for
    the reflexive one. Since R is empty, there isn't a way to relate ***every*** $x$ to itself.

    - The one subtlety is that if both R = $\varnothing$ and $X = \varnothing$,
    then the reflexive property holds along with all others (all elements of an
    empty set are related to themselves via an empty relation).

- **reflexive** ($xRx$):

  - The relation $\leq$ on the set of integers where R = ${(x, x) | \hspace{0.5em} x \leq x}$
  (E.g. 1 $\leq$ 1, 2 $\leq$ 2, ...)

  - The relation "is reachable from" for nodes in a graph.
    R = ${(x, x) | \hspace{0.5em} \text{any node is reachable from itself}}$

- **irreflexive** ($\neg(xRx$)): The relation $\le$ on the set of integers $X$.

    - R = ${(x, x) | \hspace{0.5em} \neg(x \lt x)}$ = $\varnothing$ = $neg(1 \lt 1, 2 \lt 2, ...)$

    - R = ${(x, y) | \hspace{0.5em} x \subsetneq y}$ where $x,y$ are sets and
    elements of the powerset of set X. ($\subsetneq$ stands for "is a subset of
    and not equal to" and denotes a strict subset).

- **identity** ($xRy \to x = y$):

    - The relation "is equal to" on the set of natural numbers $X$
    R = ${(x, y) | \hspace{0.5em} x = y }$

    - The relation "the result from an identity function" where
    R = $y = f(x) = {(x, y) | \hspace{0.5em} x = y}$

- **transitive** ($xRy \land yRz \to xRz$):

    - The relation $\leq$ on the set of integers where R = ${(x, x) | x \leq x}$
  (1 $\leq$ 2 and 2 $\leq$ 3 $\to$ 1 $\leq$ 3)

    - The relation "is an ancestor of" in a graph whose nodes form a set
    $xRy$ and $yRz$ $\to$ $xRz$ i.e. node x is an ancestor to both y and z

- **symmetric** ($xRy \to yRx$):

    - For X = $\mathbb{R} \backslash {0}$ i.e. the set of reals **excluding 0**,
    multiplicative inverses i.e. $R = {(x, y) | \hspace{0.5em} x = 1/y}$

    - For X = $\mathbb{R}$ only, additive inverses i.e. $R = ${(x, y) | x = -y}$

    - For X be the set of all nodes in a graph with the depth of a node defined
    from its root. Then $R = {(x, y) | \hspace{0.5em} depth(a) = depth(b)}$

    are all symmetric

- **antisymmetric** ($xRy \land yRx \to x=y$):

    - For $X$ as the set of positive integers, xRy where R is "divides". If x
    were to divide y and y x, then the only possibility is that x = y.

    - R = ${(x, y) | \hspace{0.5em} x \subset y}$ where $x,y$ are sets and
    elements of the powerset of set X. ($\subset$ stands for "is a subset of").
    Only if $x = y$ can $xRy \land yRx$ hold

- **asymmetric** ($xRy \to \neg(yRx)$):

    - For X be the set of all nodes in a graph with R defined as "is the parent of".
      R = ${(x, y) | \hspace{0.5em} \text{node x is node y's parent}}$
      Alternatively:
      R = ${(x, x) | \hspace{0.5em} \text{node x cannot be its own parent}}$

    - The relation $\lt$ on the set of integers where R = ${(x, y) | x \lt y}$


There are two important points for each property described above where each:

- holds for a relation R if and only if it holds of its converse R$^{op}$,
defined by $xRy \iff yR^{op}x$ (courtesy of the duality principle)

- extends to Boolean combinations of the above properties i.e. those formed
using the boolean 'and' ($\land$), 'or' ($\lor$) and 'not' ($\neg$).

### The Sense in Relations

With sets as a collections of elements and relations between such elements
defined above, an idea of how we can use such relations to position elements
within the set comes from the definitions of the relations themselves.

The original idea of using relations to determine relative positions of elements
i.e. an order between them comes from a [paper](https://www.jstor.org/stable/pdf/2247671.pdf)
by Bertrand Russell titled "On the Notion of Order". The crux of the paper is
as follows:

> A casual collection of terms may be ordered by counting, in which
> case they are correlated with the integers; by speech, in which case
> they are correlated with a series of times; or by writing, in which
> case they correlated with a series of places. But the order arises,
> in each case, from the intrinsic order of the integers, the times,
> or the places respectively. These have an order independent of our
> caprice-they form what I shall call independent or self-sufficient series.
> The casual terms correlated with them form, on the contrary, only
> a series by correlation. Series by correlation are generated from
> self-sufficient series as follows: If there be a self-sufficient series
> A, B, C, D, . . . a collection of terms $\alpha$, $\beta$ ... and a
> specific relation R which subsists between $alpha$ and A, and $\beta$ and B,
> etc., but not between $\alpha$ and B or C or D or etc. (with similar
 exclusions for $\beta$ ...), then $\alpha$, $\beta$ ... acquire, by
 correlation with A, B, C, D, the order which belongs intrinsically to
 A, B, C, D. Thus all orders by correlation are logically
 dependent upon intrinsic orders. The latter alone will be
 considered in what follows.

> Order depends fundamentally upon relations having what mathematicians
> call sense, i.e., such that the relation of A to B is different from
> that of B to A. Such are east and west, greater and less, before and
> after, etc. But if order is to arise, another condition is necessary.
> It must be possible for the same relation with opposite senses to
> attach to a given term. This excludes such relations as occupation
> of a place or a time. For though a time may be occupied by an event,
> there is nothing which the time itself can occupy; and similarly as
> regards a place. Where both conditions are satisfied, we in general
> have an order. That is, if there be any relation R, having two senses
> R$_{1}$, R$_{2}$; and if a term B have the relation R$_{1}$ to A, while it has the
> relation R$_{2}$ to C, then B is between A and C, and the three terms have the,
> order ABC or CBA. Thus these two conditions  are necessary for an intrinsic
> order of three terms, and become sufficient if we add that BR$_{1}$A, BR$_{2}$C
> are to imply the *denial* (emphasis mine) of AR$_{1}$C"


The idea is that a "collection of terms" (a set) with binary relations between
its elements has an "intrinsic" order where if R is a relation on elements
$x, y, z \in$ set $X$ with the property of being:

- asymmetric (($xRy \to \neg(yRx)$))
- transitive ($xRy \land yRz \to xRz$)

then elements $x, y, z$ can be compared using relations such as "is derived from",
"is less than", "is contained in", "happened before (/after)", "comes before". The
asymmetry ensures the transitivity of the relation occurs only in one direction,
without which there would be no way to put elements from $X$ in any distinct, comparative
order. This is the "sense" talked about in the paper and translates to the common sense
notion of order we use in our thinking and everyday speech.

#### Types of Orders

From the fundamental understanding of an order in the last section, let's build
the definitions by adding or slightly modifying properties of relations.

If we were to add:

- ***irreflexive*** ($\neg(xRx$))
- transitive ($xRy \land yRz \to xRz$) (**remains the same**)
- asymmetric (($xRy \to \neg(yRx)$)) (**remains the same**)

then a relation $R$ on ($x, y, z \in$) set $X$ is a **(strict) partial order**. The "partial"
signifies that the relation holds only for those elements in the set which can
be related using $R$ implying that it is not necessary for each element in $X$
to be related to every other element. The "strict" ensures that elements in $X$
can only be related to other element, never to itself.

Modifying the above definition to:

- ~~ir~~***reflexive*** ($xRx$)
- transitive ($xRy \land yRz \to xRz$) (remains the same)
- ~~asymmetric (($xRy \to \neg(yRx)$))~~ **antisymmetric** ($xRy \land yRx \to x=y$)

defines a ***weak partial order*** and is denoted by $(X, ≤)$. The set with such a order
is a (weakly) ***partially ordered set*** (or a ***poset***). The "weak" signifies that
elements can be related to themselves.

An interesting mathematical property is that a relation is asymmetric if and only if
it is both antisymmetric and irreflexive. So the asymmetry property of the strict
partial order subsumes both an irreflexive property (superfluous in the definition actually)
and an antisymmetry property. Weakening the definition to make the relation
reflexive means the asymmetry property can no longer hold i.e. now when $xRy$,
it is possible $yRx$. With the addition of antisymmetry, this can only be true
when $x = y$. This ensures that two elements can only be related in "both directions"
if they are the same, implying that the equivalent guarantees
of the asymmetry property are maintained in the presence of reflexivity
for weak partial orders.

To work through a very simple example of a poset, let's take a set $S$ = {1,2,3}
and its powerset P($S$) = {$\varnothing$, {1}, {2}, {3}, {1,2}, {1,3}, {2,3}, {1, 2, 3}}.
With $R$ defined as $\subseteq$ i.e. subset, $R$ is:

- reflexive - a set is always its own subset ({1} $\subseteq {1}. {2} $\subseteq$ {2} in P($S$))
- transitive - any element S$_1$ within S is a subset of another element S$_2$
which in turn is the subset of another element S$_3$ ({1} $\subseteq$ {1,3}
$\subseteq$ {1,2,3} $\implies$ {1} $\subseteq$ {1,2,3}; all elements is P($S$)
are subsets of the maximal element {1,2,3})
- antisymmetric - every element S$_1$ of P($S$) is subset of another element S$_2$;
if S$_2$ is a subset of S$_1$, then S$_1$ = S$_2$ ({1,2} $\subseteq$ {1,2} and
{1,2} $\subseteq$ {1,2} only when {1,2} = {1,2})

<!-- (insert diagram- Hasse) -->

An poset $X$ is termed a **chain** or a **linearly ordered set** or a **totally
ordered set** when any two elements of $X$ are comparable ($\forall x, y \in X,
xRy \lor yRx$).

The book ["Introduction to Lattices and Order"](https://www.cambridge.org/core/books/introduction-to-lattices-and-order/946458CB6638AF86D85BA00F5787F4F4) covers many more definitions and examples
on orders. The next topic that arises from the study of relations and orders are
lattices which I'll write it up in my next blog post.


References:

- Notes on Lattices from a course on [Algebraic Logic](http://boole.stanford.edu/cs353/handouts/book1.pdf)
- Copy of [Lattices and Order](https://paperpile.com/shared/sYA9j_dWBRk6w9lI5zo8G7Q)
