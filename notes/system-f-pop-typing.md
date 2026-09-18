---
title: "Jigsawing an extended System-F calculus"
date: 2026-09-18
tags: [note, system-f]
katex: true
live: true
---

I have been rather slow in coming up with new posts for several reasons, the
most important being that I don't think what I can come up with is anything
worth writing about. This attitute hasn't been really productive because the
focus remains on having something new or fresh every single time I write.
To break out of this rut, I thought I would follow the advice given by my
supervisor to all of us in our research group and try something new: put up quick-and-dirty drafts, half-baked ideas, something sketched out for
things I learn, slowly figure out, test or just play with. In short, convey the
fun and frustration of working with programming language ideas.

## Plain Old System F

I have been recently reading [Lightweight Linear Types in System
$F^{\circ}$](https://www.cis.upenn.edu/~stevez/papers/MZZ10.pdf) among other
papers which describe ways to incorporate linear types into their type systems.
This one adds linear types to
[System-F](<https://en.wikipedia.org/wiki/System_F>). To those familiar with the
[simply typed lambda
calculus](https://en.wikipedia.org/wiki/Simply_typed_lambda_calculus), the
following terms are canonical:

$$
\lambda x{:}\tau.\,x \;:\; \tau \to \tau
$$

$$
\lambda x{:}\sigma.\,\lambda y{:}\tau.\,x \;:\; \sigma \to \tau \to \sigma
$$

$$
\lambda f{:}\sigma\to\tau.\,\lambda g{:}\rho\to\sigma.\,\lambda x{:}\rho.\,f\,(g\,x) \;:\; (\sigma\to\tau) \to (\rho\to\sigma) \to \rho \to \tau
$$

In each of the terms above,  $\tau$ or $\sigma$ can be replaced by more than one
type to produce:

$$
\lambda x{:}\text{Bool}.\,x \;:\; \text{Bool} \to \text{Bool}
$$
$$
\lambda x{:}\text{Nat}.\,x \;:\; \text{Nat} \to \text{Nat}
$$
$$
\lambda  x{:}\text{Nat}.\,\lambda y{:}\text{Bool}.\,x \;:\; \text{Nat} \to
\text{Bool} \to \text{Nat}
$$
$$
\lambda x{:}\text{Bool}.\,\lambda y{:}\text{Bool}.\,x \;:\; \text{Bool} \to \text{Bool} \to \text{Bool}
$$
$$
\lambda f{:}\text{Bool}\to\text{Nat}.\,\lambda g{:}\text{Nat}\to\text{Bool}.\,\lambda x{:}\text{Nat}.\,f\,(g\,x) \;:\; (\text{Bool}\to\text{Nat}) \to (\text{Nat}\to
\text{Bool}) \to \text{Nat} \to \text{Nat}
$$

In each case, the individual terms have different types but the
shape of the result is the same:

- for the first, it's a term of the same type as the input
- for the second, it's the first input term and it's type
- for the third, it's a the result of the composition of two functions where one
  takes the output of another; the output type is that of the first function (f)

Taking the first lambda term and plugging in **any** type for a variable would
univeralize the type. Mathematically:
$$
\forall \tau.  \lambda x{:}\tau.\,x
$$

encompasses any input **type** for the term x in the entire lambda expression.
This is what `System-F` does.

**Syntax**

$$
\begin{aligned}
\tau &::= \alpha \mid \tau_1 \to \tau_2 \mid \forall \alpha.\,\tau
  &&\text{types} \\
e &::= x \mid \lambda x{:}\tau.\,e \mid e\ e \mid \Lambda \alpha.\,e \mid e[\tau]
  &&\text{expressions} \\
v &::= \lambda x{:}\tau.\,e \mid \Lambda \alpha.\,e
  &&\text{values} \\
\Gamma &::= \cdot \mid \Gamma, \alpha \mid \Gamma, x{:}\tau
  &&\text{contexts}
\end{aligned}
$$

The $\forall \alpha.\,\tau$ is universal quantification over types where for
terms, it is $\Lambda \alpha.\,e$. $e[\tau]$ is a **type** $\tau$ applied to the
term akin to how $e \hspace{0.3em}e$ applies one **term** to another.

Note that the contexts now store not just typed terms but also individual types.

**Typing**

The typing rules for `System-F` are the rules for the simply typed lambda calculus:

**[T-Var]**

$$
\dfrac{x{:}\tau \in \Gamma}{\Gamma \vdash x : \tau}
$$

**[T-Abs]**

$$
\dfrac{\Gamma, x{:}\tau_1 \vdash e : \tau_2}{\Gamma \vdash \lambda x{:}\tau_1.\,e : \tau_1 \to \tau_2}
$$

**[T-App]**

$$
\dfrac{\Gamma \vdash e_1 : \tau_1 \to \tau_2 \qquad \Gamma \vdash e_2 : \tau_1}{\Gamma \vdash e_1\ e_2 : \tau_2}
$$

to which the following are added:

**[T-TAbs]**

$$
\dfrac{\Gamma, \alpha \vdash e : \tau \qquad \alpha \notin \Gamma}{\Gamma \vdash \Lambda \alpha.\,e : \forall \alpha.\,\tau}
$$

Here given `e` is type-checked in a context that is extended with the type
**$\alpha$**. **$\alpha$** is abstracted over in the expression `e` i.e.
**$\alpha$**  is a placeholder for a type within e and can be replaced by any
type that makes `e`  type check to $\tau$,

**[T-TApp]**

$$
\dfrac{\Gamma \vdash e : \forall \alpha.\,\tau'}{\Gamma \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}
$$

With terms abstracted over types, the `T-TApp` rule applies specific types to
such terms. It's important to note that the resulting type of the overall term
never changes ($\tau'$ remains $\tau'$). It's only an abstract type within `e`,
$\alpha$, that gets replaced by an actual one $\alpha$ to produce a resulting term.

## F to F-pop

The new idea in the paper is to bring in linear types via **kinds**.

I should write an entirely new note on
[kinds](https://en.wikipedia.org/wiki/Kind_(type_theory)) but for our purpose
here, simply put, a kind system classifies types.

- For simple types that can be constructed
**without** the input of any other types e.g. Nat, Bool, the kind is $\star$.
- A type constructor that takes one input type
  - In OCaml, a type constructor
for constructing lists that takes in a type, say 'a and kind $\star$, to
construct a list
(of type 'a list and kind $\star$) has kind $\star \to \star$.
- For a function type is of $\alpha \to \beta$ where $\alpha$ is the input type and $\beta$ is the output type.
  - When the function is **applied** to a value of type
  $\alpha$ (kind $\star$), the result is of
  type $\beta$ and kind $\star$.
  - For the *function constructor itself* of type $\alpha \to \beta$, the kind
    is a constructor that first takes in a type $\alpha$ (kind $\star$) to return
    *another* constructor that takes in a type $\beta$ (again kind $\star$) to
    finally return a type of kind $\star$. So the kind for the entire
    constructor is $\star \to \star \to \star$

In $F^{\circ}$, there are two kinds instead of the one base kind in `System-F`.
The second kind is:

$$\circ$$

that denotes linearity. Linear types encompass values that are consumed only
once i.e. used only once in a computation.
(I should also write another note/post on sub-structural types of which linear
types are an example.)

The kind $\star$ continues to denote types that are not linear.

The sets of types and kinds now are:
$$
\tau ::= \alpha \mid \tau_1 \to \tau_2 \mid \forall\alpha.\tau \qquad \kappa ::= \star \mid \circ
$$

Since the context is constructed as a set of variable and types, let's perform a
small transformation to its form. The set of all types in a context can be considered
as a set with two sorts:

$$
\Gamma^{types} ::= \{ (\tau {:} \star), (\tau {:} \circ) \}
$$

With variables having type $\tau$ and kind $\kappa$, the set of variables can be
binned into the two sorts as:

$$
\Gamma^{vars} ::= \{ (x {:} \tau^{\star}), (x {:} \tau^{\circ}) \}
$$

Now the context is:
$$
\begin{aligned}
\Gamma ::=  \cdot \mid (\Gamma^{types} + \Gamma^{vars}) \\
\text{which can be rewritten as} \\
\Gamma ::= \cdot \mid \{ (\tau {:} \star), (\tau {:} \circ), (x {:} \tau^{\star}), (x {:}
\tau^{\circ}) \}
\end{aligned}
$$

## Jigsawing System-F-pop

When reading through the paper, I could not help being reminded of something
from my childhood: [jigsaw
puzzles](https://en.wikipedia.org/wiki/Jigsaw_puzzle). I had a few, one of them
actually a GI Joe-themed one (I actually found a [vintage puzzle set](https://www.ebay.com/itm/168672158617?itmmeta=01M2R5XHF7TEH1N616S1R21WKQ&hash=item2745a4e399:g:9QoAAeSwRR1qn00z&itmprp=enc%3AAQALAAAA4DKQclQvzFwZQpmMrsO4LupezmLFgdZXhh28YT2f8CIk0h8atfToYXuSIzC4HgiP2%2B%2FOEdcBWIDWDUj4wLBf7qVZ9NOU%2BHxFVwZgU5ZQN8TeSiJO91e1VwOWW4WLemL4vUf%2FMeqCqA%2BuyNA7hwEmTa5KrWhvY3NLrBGwm9EnuScxAQ912p9jhxNdRhpad7mFSF9GBN8G13snjgf%2BVfGhjFGbENTFPweyv5T7RwWAuCVL3%2FWk0cujHhOiWATM4Yl%2BtKsbVIyElk%2BzUWWptBg9iGJzPJLNQdNeRD3BpVGmRoBX%7Ctkp%3ABk9SR-CX9oWWaA) which is an exact
copy of the one I had), all of which were valiant efforts by my parents to keep
my occupied and hence quiet.

My strategy to solve them was to find a color or shape or some combination of both
to start with. A few pieces that seemed easier to put together, a bit more
obivous than others and then slowly build out from that nucleus. Sometimes, one
could create subsets of the larger whole and put them together.

Reading the typing rules for F-pop is fine but (re)constructing them was the
more interesting exercise. Sort of like taking a
few easy pieces of `System-F` and then adding other required pieces that fit
just right to come up with whole (and sound)
`System-F-pop`.

To start with, the types are:

$$
\tau ::= \alpha \mid \tau_1 \to \tau_2 \mid \forall\alpha.\tau
$$

the kinds are:
$$
\kappa ::= \star \mid \circ
$$

and the context is:
$$
\Gamma ::= \cdot \mid \{ (\tau {:} \star), (\tau {:}\circ), (x {:} \tau^{\star}), (x {:} \tau^{\circ}) \}
$$

The two kinds are related by the **Kind-Sub** rule:

$$
\dfrac{\Gamma \vdash \tau : \star}{\Gamma \vdash \tau : \circ}
$$

In a context, a type $\tau$ with kind $\star$ can be used as the same type
$\circ$, never the opposite.

### The core piece to start with: term abstractions

Abstractions over terms (variables) are functions of the following type
where $\kappa_1$, $\kappa_2$ both can be $\star$ or $\circ$:
$$
\tau_1 {:} \kappa_1 \to \tau_2 {:} \kappa_2
$$

In `System-F-pop`, every type has a kind including function types which can be
marked with either kind as:

$$
\tau_1 {:} \kappa_1 \xrightarrow{\star} \tau_2 {:} \kappa_2
$$

denotes a function that can be called any number of times, while

$$
\tau_1 {:} \kappa_1 \xrightarrow{\circ} \tau_2 {:} \kappa_2
$$

denotes one which can be called only once, **irrespective of what kinds both types $\tau_1$, $\tau_2$ are.**

Let's take the `T-Abs` rule and start adding kinds to it.

**T-Abs-1**

$$
\dfrac{\Gamma, x{:}\tau_1^\star \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ}{\Gamma \vdash \lambda^\star x{:}\tau_1.\,e : \tau_1 \xrightarrow{\star} \tau_2}
$$

**T-Abs-2**

$$
\dfrac{\Gamma, x{:}\tau_1^\star \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ}{\Gamma \vdash \lambda^\circ x{:}\tau_1.\,e : \tau_1 \xrightarrow{\circ} \tau_2}
$$

**T-Abs-3**

$$
\dfrac{\Gamma, x{:}\tau_1^\circ \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ}{\Gamma \vdash \lambda^\circ x{:}\tau_1.\,e : \tau_1 \xrightarrow{\circ} \tau_2}
$$

**T-Abs-4**

$$
\dfrac{\Gamma, x{:}\tau_1^\circ \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ}{\Gamma \vdash \lambda^\star x{:}\tau_1.\,e : \tau_1 \xrightarrow{\star} \tau_2}
$$

In each of the four instances for the T-Abs rule, the expression abstracted over
can be linear or unrestricted. If the bound variable is linear (instances 3 and
4), it will only be used once within the lambda term. But the most important
thing to note is that the kind of the function type is independent of that of the
bound variable.

Generalizing the kind of the bound variable:

$$
\dfrac{\Gamma, x{:}\tau_1^{\kappa_1} \vdash e : \tau_2^{\kappa_2} \qquad \kappa_1, \kappa_2, \kappa_3 := \star \mid \circ}{\Gamma \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}
$$

Do note that the $\kappa_3$ over the
symbol for $\lambda$ is the same $\kappa_3$ for the function type and denotes that the whole lambda
term of function type $\tau_1 \to \tau_2$ has kind $\kappa_3$.
Now if kinds $\kappa_1$ and $\kappa_2$ are completely independent of kind
$\kappa_3$, or in other words have no bearing on the kind determined for
$\kappa_3$ , then what other factor does?

The answer is something outside of the lambda term itself. This makes the lambda
**a closure that captures some value** that is (obviously) not $x$ and not bound
in
$e$. If a term or a value captured from outside $\lambda$ is linear, then the
closure formed by the lambda term capturing such a value is also linear. This
means that
having a captured linear value makes the lambda term be used only once without any
consideration of what the kinds for the bound variable and expression abstracted
are. If *a term or a value captured from the surrounding scope is unrestricted*, then
the **closure can either be linear or unrestricted.**

Up untill now, the context has been partioned as:

$$
\Gamma ::= \cdot \mid \{ (\tau {:} \star), (\tau {:}\circ), (x {:} \tau^{\star}), (x {:} \tau^{\circ}) \}
$$

The type system needs to make a simple determination of whether something
captured is linear or not. Maintaing four subsets in a larger set is more
cumbersome that two different sets, a practice also present in other type
systems. Moving the subset of linear variables out creates a new context:

$$
\Delta ::= \cdot \mid \Delta, x{:}\tau^\circ
$$

which only contains expressions (variables) that are of linear kind.

The original context now is:
$$
\Gamma ::= \cdot \mid \{ (\tau {:} \star), (\tau {:}\circ), (x {:} \tau^{\star})\}
$$

**T-Abs (linear variable captured)**

With two seperate contexts, $\Gamma$ and $\Delta$ and a variable captured from
$\Delta$, the rule now adds a side condition:

$$
\dfrac{\Gamma, x{:}\tau_1^{\kappa_1} \vdash e : \tau_2^{\kappa_2} \qquad \kappa_1, \kappa_2 := \star \mid \circ \qquad e \text{ captures at least one variable from } \Delta}{\Gamma \vdash \lambda^\circ x{:}\tau_1.\,e : \tau_1 \xrightarrow{\circ} \tau_2}
$$

Rewriting it slightly:

$$
\dfrac{\Gamma, x{:}\tau_1^{\kappa_1} \vdash e : \tau_2^{\kappa_2} \qquad \kappa_1, \kappa_2 := \star \mid \circ \qquad \Delta = \cdot \lor \kappa_3 = \circ}{\Gamma \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}
$$

This is a neater rule to come up with and it says that either the context
captures something linear ($\kappa_3 = \circ$) forcing the closure to be linear or the context cannot capture
anything linear ($\Delta$ is empty) leaving the choice of the function kind to
either linear or unrestricted.

Having constucted two
contexts, the rule needs to account type-checking *under both contexts* in order
to satisfy the linear-value-captured requirement. For now, this will have to be
put aside because we haven't fully fleshed out the typing rules for both the
contexts including ones where expressions (variables) are added to them. Let's first finish the side conditions for `T-Abs`.

**T-Abs (side conditions complete)**

$$
\dfrac{\Gamma, x{:}\tau_1^{\kappa_1} \vdash e : \tau_2^{\kappa_2} \qquad \kappa_1, \kappa_2 := \star \mid \circ \qquad (\Delta \neq \cdot \land \kappa_3 = \circ) \lor (\Delta = \cdot \land \kappa_3 := \star \mid \circ)}{\Gamma \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}
$$

The left half of the disjunction specified when something **linear** captured
*and κ3 is required to be linear as a result*. The right half spelss out when
**nothing linear can be captured** and $\kappa_3$ is free to be either linear or
restricted when it fits as a piece into a larger program that's type-checked.

### Term Applications: The T-App rule

In `System-F`, the rule for term applications is:
$$
\dfrac{\Gamma \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma \vdash e_2 : \tau_1^{\kappa_2} \qquad \kappa_1,\kappa_2,\kappa_3 := \star \mid \circ}{\Gamma \vdash e_1\ e_2 : \tau_2^{\kappa_3}}
$$

This rule is the obverse of T-Abs in that $\kappa_1$ here is the kind of a
lambda term. Since $\kappa_1$ was determined by capturing of values by the lambda
term, $\kappa_2$ need not be the same as $\kappa_1$ at all. For the rule to
apply, the types $\tau_1$ in $e_1$ and $e_2$ should match. The kind of the
result of the application, again, can be either i.e. whichever value for kind
satisfies all other typing constraints in the program.

**T-App (both contexts in type checking?)**

We didn't have enough pieces to complete the `T-Abs` rule but let's try and see
if the T-App rule can be completety type checked using both contexts. Starting
with the first fragment of the `T-App` rule:

$$
\dfrac{\Gamma;\Delta \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \text{...}}{\text{...}}
$$

then:

$$
\dfrac{\Gamma;\Delta \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma;\Delta \vdash e_2 : \tau_1^{\kappa_2} \qquad}{\text{...}}
$$

to give:
$$
\dfrac{\Gamma;\Delta \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma;\Delta \vdash e_2 : \tau_1^{\kappa_2} \qquad}{\Gamma;\Delta \vdash e_1\ e_2 : \tau_2^{\kappa_3}}
$$

But the above isn't quite right. Because the linear contexts being the same for
all terms in the premises and the conclusions implies that all the terms are
type checked for the same set of linear variables. A variable **captured
within $e_1$ will be eventually used within $e_1$ exclusively. If $e_2$ has the
same context $\Delta$, the same variable has to be potentially allowed exclusive use within
$e_2$ - something that would allow a linear variable to be used twice.** To avoid
this mistake, the premises must have **disjoint linear contexts**:

$$
\dfrac{\Gamma;\Delta_1 \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma;\Delta_2 \vdash e_2 : \tau_1^{\kappa_2} \qquad \Delta_1 \uplus \Delta_2 = \Delta_3 \qquad \kappa_1,\kappa_2,\kappa_3 := \star \mid \circ}{\Gamma;\Delta_3 \vdash e_1\ e_2 : \tau_2^{\kappa_3}}
$$

The linear context $\Delta_3$ created by the disjoint union of the contexts
$\Delta_1$, $\Delta_2$ is the one in which, along with $\Gamma$, that the
application of $e_2$ to $e_1$ is type checked.

### Rules for Delta

So far, we have an (incomplete) `T-Abs` rule, a (complete) `T-App` rule. But
there is something in the `T-App` rule that we haven't fully worked out.

The linear context:

$$
\Delta ::= \cdot \mid \Delta, x{:}\tau^\circ
$$

stores variables that can only be used once. So the definition must also include
a base case where $x$ is a variable and:

$$
\dfrac{x \notin \Delta}{\Delta \to \Delta, x{:}\tau^\circ}
$$

This is to a single linear context. But in the `T-App` rule, the side condition
specifies the disjoint union of two linear contexts. How do we define that
operation? The base/empty case for both is the simplest:

$$
\cdot \uplus \cdot = \cdot
$$

With two sides to the union, an element can either to the left set:

$$
\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1, x{:}\tau^\circ \uplus \Delta_2 = \Delta, x{:}\tau^\circ}
$$

or the right one:
$$
\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1 \uplus \Delta_2, x{:}\tau^\circ = \Delta, x{:}\tau^\circ}
$$

and the resulting context is $\Delta$ to which a linear variable not already
present in $\Delta$ is added.

### The T-Var rule

The `T-Var` rule:

$$
\dfrac{x{:}\tau^\kappa \in \Gamma}{\Gamma \vdash x^\kappa : \tau}
$$

specifies the types and kinds to variables in the context with unrestricted
kinds. Writing out what $\kappa$ is in this context:

$$
\dfrac{x{:}\tau^\kappa \in \Gamma \qquad \kappa := \star}{\Gamma \vdash x^\kappa : \tau}
$$

This rule is also incomplete like `T-Abs` as the linear context $\Delta$ has not
been included in the type checking. I couldn't think of what shape to put this
rule in, so I put it in the same incomplete slot as `T-Abs` until I could come
back to complete two (or more) rules.

### The T-TAbs rule

Adding kinds to the `T-TAbs` rule:

$$
\dfrac{\Gamma, \alpha \vdash e : \tau \qquad \alpha \notin \Gamma}{\Gamma \vdash \Lambda \alpha.\,e : \forall \alpha.\,\tau}
$$

results in:

$$
\dfrac{\Gamma, \alpha{:}\kappa_1 \vdash e : \tau^{\kappa_2} \qquad \alpha \notin \Gamma}{\Gamma \vdash \Lambda \alpha{:}\kappa_1.\,e : \forall \alpha{:}\kappa_1.\,\tau}
$$

The kinds $\kappa_1$ and $\kappa_2$ are independent of each other and the
**type and kind** of the expression never changes. The abstraction over **type**
$\alpha$ allows the type system to plug in any type of kind $\kappa_1$ for
checking $e$.

Types and their kinds reside in the context $\Gamma$, so adding the linear
context to the rule:

$$
\dfrac{\Gamma, \alpha{:}\kappa_1;\Delta \vdash e : \tau^{\kappa_2} \qquad \alpha \notin \Gamma}{\Gamma;\Delta \vdash \Lambda \alpha{:}\kappa_1.\,e : \forall \alpha{:}\kappa_1.\,\tau}
$$

does not change the linear context at all. With $\Gamma$ extended by adding
$\alpha$, $\alpha$ gets added to the subset of types in it without capturing or
affecting any variables in $e$.

### The T-TApp rule

Adding kinds to the `T-TApp` rule:

$$
\dfrac{\Gamma \vdash e : \forall \alpha.\,\tau'}{\Gamma \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}
$$

results in the rule:

$$
\dfrac{\Gamma \vdash e : \forall \alpha{:}\kappa_1.\,\tau' \qquad \Gamma \vdash \tau : \kappa_2 \qquad \kappa_1 = \kappa_2}{\Gamma \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}
$$

Here with application of a type to another, the kinds for both being the same is
crucial. Both types have the same shape e.g. a `Nat` and a `Bool` have kind
$\star$.

Adding $\Delta$ to the context to try and complete the rule:

$$
\dfrac{\Gamma;\Delta \vdash e : \forall \alpha{:}\kappa_1.\,\tau' \qquad \Gamma \vdash \tau : \kappa_2 \qquad \kappa_1 = \kappa_2}{\Gamma;\Delta \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}
$$

The same context $\Gamma$ has all the types, linear and unrestricted, as
separate subsets within it whereas $\Delta$ (linear terms) are not used at all.
So using the same context in the premises and conclusion of the rule is correct.

### Rules for Typing kinds

**Kind-Arr**

$$
\dfrac{\Gamma \vdash \tau_1 : \kappa_1 \qquad \Gamma \vdash \tau_2 : \kappa_2}{\Gamma \vdash \tau_1 \xrightarrow{\kappa_3} \tau_2 : \kappa_3}
$$

**Kind-TVar**

$$
\dfrac{\alpha{:}\kappa \in \Gamma}{\Gamma \vdash \alpha : \kappa}
$$

**Kind-All**

$$
\dfrac{\Gamma, \alpha{:}\kappa_1 \vdash \tau : \kappa_2 \qquad \alpha \notin \Gamma}{\Gamma \vdash \forall \alpha{:}\kappa_1.\,\tau : \kappa_2}
$$

These three above rules lay out the kind for each for arrow (function) types,
variables in $\Gamma$ and for quantified types. The `Kind-Arr` rule reiterates
that the kinds for the types within an arrow type, $\tau_1$ and $\tau_2$, are
independent of the type of the arrow/function itself.

---

> ### Summary — rules derived so far
>
> **Kind-Sub**
> $$\dfrac{\Gamma \vdash \tau : \star}{\Gamma \vdash \tau : \circ}$$
>
> **T-Abs**
> $$\dfrac{\Gamma, x{:}\tau_1^{\kappa_1} \vdash e : \tau_2^{\kappa_2} \qquad
> \kappa_1, \kappa_2 := \star \mid \circ \qquad (\Delta \neq \cdot \land
> \kappa_3 = \circ) \lor (\Delta = \cdot \land \kappa_3 := \star \mid
> \circ)}{\Gamma \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1
> \xrightarrow{\kappa_3} \tau_2}$$
>
> **T-App**
> $$\dfrac{\Gamma;\Delta_1 \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma;\Delta_2 \vdash e_2 : \tau_1^{\kappa_2} \qquad \Delta_1 \uplus \Delta_2 = \Delta_3 \qquad \kappa_1,\kappa_2,\kappa_3 := \star \mid \circ}{\Gamma;\Delta_3 \vdash e_1\ e_2 : \tau_2^{\kappa_3}}$$
>
> **T-Var**
> $$\dfrac{x{:}\tau^\kappa \in \Gamma}{\Gamma \vdash x^\kappa : \tau}$$
>
> **Delta-Empty**
> $$\cdot \uplus \cdot = \cdot$$
>
> **Delta-Left**
> $$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1, x{:}\tau^\circ \uplus \Delta_2 = \Delta, x{:}\tau^\circ}$$
>
> **Delta-Right**
> $$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1 \uplus \Delta_2, x{:}\tau^\circ = \Delta, x{:}\tau^\circ}$$
>
> **T-TAbs**
> $$\dfrac{\Gamma, \alpha{:}\kappa_1;\Delta \vdash e : \tau^{\kappa_2} \qquad \alpha \notin \Gamma}{\Gamma;\Delta \vdash \Lambda \alpha{:}\kappa_1.\,e : \forall \alpha{:}\kappa_1.\,\tau}$$
>
> **T-TApp**
> $$\dfrac{\Gamma;\Delta \vdash e : \forall \alpha{:}\kappa_1.\,\tau' \qquad \Gamma \vdash \tau : \kappa_2 \qquad \kappa_1 = \kappa_2}{\Gamma;\Delta \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}$$
>
> **Kind-Arr**
> $$\dfrac{\Gamma \vdash \tau_1 : \kappa_1 \qquad \Gamma \vdash \tau_2 : \kappa_2}{\Gamma \vdash \tau_1 \xrightarrow{\kappa_3} \tau_2 : \kappa_3}$$
>
> **Kind-TVar**
> $$\dfrac{\alpha{:}\kappa \in \Gamma}{\Gamma \vdash \alpha : \kappa}$$
>
> **Kind-All**
> $$\dfrac{\Gamma, \alpha{:}\kappa_1 \vdash \tau : \kappa_2 \qquad \alpha \notin \Gamma}{\Gamma \vdash \forall \alpha{:}\kappa_1.\,\tau : \kappa_2}$$

---

Writing all the rules in a table is me trying to put together smaller pieces to
form the larger picture.
The `T-App`, the `Delta` rules, `T-TAbs`, `T-TApp` and the rules for kinding
types are as complete as the kinds and contexts allow The `T-Abs` and the
`T-Var` rules are the one which type check kinds of linear or unrestricted types
**but do not take the linear context (Delta) into consideration**. These rules
need to be rewritten to complete the puzzle.

Let's start with trying with the simple requirement: The `T-Abs` rule needs
$\Delta$ along with $\Gamma$ to correctly type check. When a variable is added
as a binding in the premise of the rule, which context should it be put into?

**VarAdd-Lin**

The answer when the variable is linear is the linear context. The rule that
describes this is:

$$
\dfrac{\Gamma \vdash \tau : \circ \qquad x \notin \Gamma, \Delta \ (x \text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow \Gamma; (\Delta, x{:}\tau)}
$$

Here $\Delta$ and $\Gamma$ form two discrete subsets making up the entire
context $[\Gamma;\Delta]$ to which $x$ is added. The  $\rightsquigarrow$ denotes
the variable being correctly put into the linear context.

**VarAdd-Un**

This rule is for when the fresh variable added to $[\Gamma;\Delta]$ is
unrestricted and put into $\Gamma$:

$$
\dfrac{\Gamma \vdash \tau : \star \qquad x \notin \Gamma, \Delta \ (x \text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow (\Gamma, x{:}\tau); \Delta}
$$

Now `T-Abs` can be rewritten.

**T-Abs (step 1 to update first premise only)**

$$
\dfrac{[\Gamma;\Delta], x{:}\tau_1 \rightsquigarrow \Gamma';\Delta' \qquad \Gamma';\Delta' \vdash e : \tau_2^{\kappa_2} \qquad \ldots}{\ldots}
$$

The `VarAdd-Lin`/`VarAdd-Un` rules are used to put $x$ into the correct context
to create a new context $[\Gamma';\Delta']$ and the expression `e` now typed
with this updated context instead of plain
$[\Gamma;\Delta]$  

**T-Abs (step 2 to update second premise only)**

$$
\dfrac{\ldots \qquad \kappa_2 := \star \mid \circ \qquad \ldots}{\ldots}
$$

With `VarAdd-Lin`/`VarAdd-Un` having used the kind associated with type $\tau_1$
for $x$, the side rule can be simplified to only keep $\kappa_2$.

**T-Abs (step 3 to update third premise only)**

$$
\dfrac{\ldots \qquad (\Delta \neq \cdot \land \kappa_3 = \circ) \lor (\Delta = \cdot \land \kappa_3 := \star \mid \circ) }{\ldots}
$$

The other side condition listing out the disjunctive requirement for kinds uses
the original $\Delta$. Should this be changed or not?

$\Delta$ denotes the context that contains linear variables that can be captured
within $e$. $\Delta'$ is $\Delta$ with $x$ added. Since $x$ and captured
values are never the same, letting the rule keep $\Delta$ is correct and
sufficient.

**T-Abs (step 4 to update the conclusion only)**

$$
\dfrac{\ldots}{\Gamma;\Delta \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}
$$

The conclusion is now typed under both $\Gamma$ and $\Delta$. Again should
$\Delta$ be updated to $\Delta'$?

Here entire lambda expression $\lambda x{:}\tau_1.\,e$ is a ready construct
within which both $x$ and $e$ are already type checked. So both
$[\Gamma';\Delta']$ having already been used to type check $e$, the lambda
construct can be type checked with $[\Gamma;\Delta]$ alone.

**T-Abs completed**

Putting together the last four rewritten parts of the `T-Abs` rule gives a
satisfyingly complete rule in `System-F`$^\circ$:

$$
\dfrac{[\Gamma;\Delta], x{:}\tau_1 \rightsquigarrow \Gamma';\Delta' \qquad \Gamma';\Delta' \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ \qquad (\Delta \neq \cdot \land \kappa_3 = \circ) \lor (\Delta = \cdot \land \kappa_3 := \star \mid \circ)}{\Gamma;\Delta \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}
$$

---

> ### Updated Summary
>
> **Kind-Sub**
> $$\dfrac{\Gamma \vdash \tau : \star}{\Gamma \vdash \tau : \circ}$$
>
> **VarAdd-Lin** *(new)*
> $$\dfrac{\Gamma \vdash \tau : \circ \qquad x \notin \Gamma, \Delta \ (x \text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow \Gamma; (\Delta, x{:}\tau)}$$
>
> **VarAdd-Un** *(new)*
> $$\dfrac{\Gamma \vdash \tau : \star \qquad x \notin \Gamma, \Delta \ (x \text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow (\Gamma, x{:}\tau); \Delta}$$
>
> **T-Abs** *(updated)*
> $$\dfrac{[\Gamma;\Delta], x{:}\tau_1 \rightsquigarrow \Gamma';\Delta' \qquad \Gamma';\Delta' \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ \qquad (\Delta \neq \cdot \land \kappa_3 = \circ) \lor (\Delta = \cdot \land \kappa_3 := \star \mid \circ)}{\Gamma;\Delta \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}$$
>
> **T-App**
> $$\dfrac{\Gamma;\Delta_1 \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma;\Delta_2 \vdash e_2 : \tau_1^{\kappa_2} \qquad \Delta_1 \uplus \Delta_2 = \Delta_3 \qquad \kappa_1,\kappa_2,\kappa_3 := \star \mid \circ}{\Gamma;\Delta_3 \vdash e_1\ e_2 : \tau_2^{\kappa_3}}$$
>
> **T-Var**
> $$\dfrac{x{:}\tau^\kappa \in \Gamma}{\Gamma \vdash x^\kappa : \tau}$$
>
> **Delta-Empty**
> $$\cdot \uplus \cdot = \cdot$$
>
> **Delta-Left**
> $$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1, x{:}\tau^\circ \uplus \Delta_2 = \Delta, x{:}\tau^\circ}$$
>
> **Delta-Right**
> $$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1 \uplus \Delta_2, x{:}\tau^\circ = \Delta, x{:}\tau^\circ}$$
>
> **T-TAbs**
> $$\dfrac{\Gamma, \alpha{:}\kappa_1;\Delta \vdash e : \tau^{\kappa_2} \qquad \alpha \notin \Gamma}{\Gamma;\Delta \vdash \Lambda \alpha{:}\kappa_1.\,e : \forall \alpha{:}\kappa_1.\,\tau}$$
>
> **T-TApp**
> $$\dfrac{\Gamma;\Delta \vdash e : \forall \alpha{:}\kappa_1.\,\tau' \qquad \Gamma \vdash \tau : \kappa_2 \qquad \kappa_1 = \kappa_2}{\Gamma;\Delta \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}$$
>
> **Kind-Arr**
> $$\dfrac{\Gamma \vdash \tau_1 : \kappa_1 \qquad \Gamma \vdash \tau_2 : \kappa_2}{\Gamma \vdash \tau_1 \xrightarrow{\kappa_3} \tau_2 : \kappa_3}$$
>
> **Kind-TVar**
> $$\dfrac{\alpha{:}\kappa \in \Gamma}{\Gamma \vdash \alpha : \kappa}$$
>
> **Kind-All**
> $$\dfrac{\Gamma, \alpha{:}\kappa_1 \vdash \tau : \kappa_2 \qquad \alpha \notin \Gamma}{\Gamma \vdash \forall \alpha{:}\kappa_1.\,\tau : \kappa_2}$$

---

The three new/updated rules,
`VarAdd-Lin`, `VarAdd-Un` and `T-Abs` make `System-F-pop`'s type system closer
to being correct and complete. But when you look over all the rules, there's one
that involves kinds of both types **without involving the two contexts** $\Delta$
and $\Gamma$.

That rule is `T-Var` where x is type checked to type $\tau$ and either kind,
linear or unrestricted. But notice that the linear context $\Delta$ is missing
from the rule.

**T-UnrestrictVar**

When the kind of $x$ is $\star$, $x$ can only be a member of the unrestricted
context $\Gamma$:

$$
\dfrac{x{:}\tau^\star \in \Gamma \qquad \Delta = ?}{\Gamma;\Delta \vdash x : \tau^\star}
$$

I had trouble thinking of what $\Delta$ would look like. The clue came from the
`Delta-Empty`, `Delta-Left`, `Delta-Right` rules.

A $\Delta$ context can be constructed from
disjoint subsets. If a variable of kind $\star$ is in $\Gamma$, there is no
linear set to construct or put this variable into. So $\Delta$ can be simply
empty here as:

$$
\dfrac{x{:}\tau^\star \in \Gamma \qquad \Delta = \cdot}{\Gamma;\Delta \vdash x : \tau^\star}
$$

The obverse happens when the variable is linear.

**T-LinVar**

Now the variable with linear kind $\circ$ can be put into the smallest set
$\Delta_x$. The typing rule is simply:

$$
\dfrac{x{:}\tau^\circ = \Delta_x}{\Gamma;\Delta_x \vdash x : \tau^\circ}
$$

When several linear variables (terms) are to be put together into one linear
context, say $y$, $z$, ..., the disjoint union of all the subsets, $\Delta_y$,
$\Delta_z$, ... make up $\Delta$.

---

> ### The complete type system for System-F-pop
>
> **Kind-Sub**
> $$\dfrac{\Gamma \vdash \tau : \star}{\Gamma \vdash \tau : \circ}$$
>
> **VarAdd-Lin**
> $$\dfrac{\Gamma \vdash \tau : \circ \qquad x \notin \Gamma, \Delta \ (x \text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow \Gamma; (\Delta, x{:}\tau)}$$
>
> **VarAdd-Un**
> $$\dfrac{\Gamma \vdash \tau : \star \qquad x \notin \Gamma, \Delta \ (x \text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow (\Gamma, x{:}\tau); \Delta}$$
>
> **T-Abs**
> $$\dfrac{[\Gamma;\Delta], x{:}\tau_1 \rightsquigarrow \Gamma';\Delta' \qquad \Gamma';\Delta' \vdash e : \tau_2^{\kappa_2} \qquad \kappa_2 := \star \mid \circ \qquad (\Delta \neq \cdot \land \kappa_3 = \circ) \lor (\Delta = \cdot \land \kappa_3 := \star \mid \circ)}{\Gamma;\Delta \vdash \lambda^{\kappa_3} x{:}\tau_1.\,e : \tau_1 \xrightarrow{\kappa_3} \tau_2}$$
>
> **T-App**
> $$\dfrac{\Gamma;\Delta_1 \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \qquad \Gamma;\Delta_2 \vdash e_2 : \tau_1^{\kappa_2} \qquad \Delta_1 \uplus \Delta_2 = \Delta_3 \qquad \kappa_1,\kappa_2,\kappa_3 := \star \mid \circ}{\Gamma;\Delta_3 \vdash e_1\ e_2 : \tau_2^{\kappa_3}}$$
>
> **T-LinVar**
> $$\dfrac{x{:}\tau^\circ = \Delta}{\Gamma;\Delta \vdash x : \tau^\circ}$$
>
> **T-UnrestrictVar**
> $$\dfrac{x{:}\tau^\star \in \Gamma \qquad \Delta = \cdot}{\Gamma;\Delta \vdash x : \tau^\star}$$
>
> **Delta-Empty**
> $$\cdot \uplus \cdot = \cdot$$
>
> **Delta-Left**
> $$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1, x{:}\tau^\circ \uplus \Delta_2 = \Delta, x{:}\tau^\circ}$$
>
> **Delta-Right**
> $$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \qquad x \notin \Delta}{\Delta_1 \uplus \Delta_2, x{:}\tau^\circ = \Delta, x{:}\tau^\circ}$$
>
> **T-TAbs**
> $$\dfrac{\Gamma, \alpha{:}\kappa_1;\Delta \vdash e : \tau^{\kappa_2} \qquad \alpha \notin \Gamma}{\Gamma;\Delta \vdash \Lambda \alpha{:}\kappa_1.\,e : \forall \alpha{:}\kappa_1.\,\tau}$$
>
> **T-TApp**
> $$\dfrac{\Gamma;\Delta \vdash e : \forall \alpha{:}\kappa_1.\,\tau' \qquad \Gamma \vdash \tau : \kappa_2 \qquad \kappa_1 = \kappa_2}{\Gamma;\Delta \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}$$
>
> **Kind-Arr**
> $$\dfrac{\Gamma \vdash \tau_1 : \kappa_1 \qquad \Gamma \vdash \tau_2 : \kappa_2}{\Gamma \vdash \tau_1 \xrightarrow{\kappa_3} \tau_2 : \kappa_3}$$
>
> **Kind-TVar**
> $$\dfrac{\alpha{:}\kappa \in \Gamma}{\Gamma \vdash \alpha : \kappa}$$
>
> **Kind-All**
> $$\dfrac{\Gamma, \alpha{:}\kappa_1 \vdash \tau : \kappa_2 \qquad \alpha \notin \Gamma}{\Gamma \vdash \forall \alpha{:}\kappa_1.\,\tau : \kappa_2}$$

---

Given the initial set of kinds for functions, contexts and types, most of the
rules inevitably end up being exactly what the paper describes. The real payoff
is in having derived some rules from others and writing out rules such as `T-Abs` in more detail
than provided in the paper, so that all side-conditions for that rule are
obvious.

### Constructed rules vs. the paper's (Figure 3), side by side

| Constructed | Paper |
| --- | --- |
| **Kind-Sub**<br>$\dfrac{\Gamma \vdash \tau : \star}{\Gamma \vdash \tau : \circ}$ | **K-Sub**<br>$\dfrac{\Gamma \vdash \tau : \star}{\Gamma \vdash \tau : \circ}$ |
| **VarAdd-Lin**<br>$\dfrac{\Gamma \vdash \tau : \circ \quad x \notin \Gamma, \Delta \ (x\text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow \Gamma; (\Delta, x{:}\tau)}$ | **B-Lin**<br>$\dfrac{\Gamma \vdash \tau : \circ \quad x \notin \Gamma, \Delta}{[\Gamma;\Delta], x{:}\tau \Supset \Gamma; (\Delta, x{:}\tau)}$ |
| **VarAdd-Un**<br>$\dfrac{\Gamma \vdash \tau : \star \quad x \notin \Gamma, \Delta \ (x\text{ fresh})}{[\Gamma;\Delta], x{:}\tau \rightsquigarrow (\Gamma, x{:}\tau); \Delta}$ | **B-Un**<br>$\dfrac{\Gamma \vdash \tau : \star \quad x \notin \Gamma, \Delta}{[\Gamma;\Delta], x{:}\tau \Supset (\Gamma, x{:}\tau); \Delta}$ |
| **T-Abs**<br>$\dfrac{[\Gamma;\Delta], x{:}\tau_1 \rightsquigarrow \Gamma';\Delta' \quad \Gamma';\Delta' \vdash e : \tau_2^{\kappa_2} \quad \kappa_2{:=}\star\mid\circ \quad (\Delta{\neq}\cdot \land \kappa_3{=}\circ) \lor (\Delta{=}\cdot \land \kappa_3{:=}\star\mid\circ)}{\Gamma;\Delta \vdash \lambda^{\kappa_3} x{:}\tau_1.e : \tau_1 \xrightarrow{\kappa_3} \tau_2}$ | **T-Lam**<br>$\dfrac{[\Gamma;\Delta], x{:}\tau_1 \Supset \Gamma';\Delta' \quad \Gamma';\Delta' \vdash e : \tau_2 \quad \Delta{=}\cdot \lor \kappa{=}\circ}{\Gamma;\Delta \vdash \lambda^\kappa x{:}\tau_1.e : \tau_1 \xrightarrow{\kappa} \tau_2}$ |
| **T-App**<br>$\dfrac{\Gamma;\Delta_1 \vdash e_1 : \tau_1 \xrightarrow{\kappa_1} \tau_2 \quad \Gamma;\Delta_2 \vdash e_2 : \tau_1^{\kappa_2} \quad \Delta_1 \uplus \Delta_2 {=} \Delta_3 \quad \kappa_1,\kappa_2,\kappa_3{:=}\star\mid\circ}{\Gamma;\Delta_3 \vdash e_1\ e_2 : \tau_2^{\kappa_3}}$ | **T-App**<br>$\dfrac{\Gamma;\Delta_1 \vdash e_1 : \tau_1 \xrightarrow{\kappa} \tau_2 \quad \Gamma;\Delta_2 \vdash e_2 : \tau_1 \quad \Delta_1 \uplus \Delta_2 {=} \Delta}{\Gamma;\Delta \vdash e_1\ e_2 : \tau_2}$ |
| **T-LinVar**<br>$\dfrac{x{:}\tau^\circ = \Delta}{\Gamma;\Delta \vdash x : \tau^\circ}$ | **T-LVar**<br>$\Gamma; x{:}\tau \vdash x : \tau$ |
| **T-UnrestrictVar**<br>$\dfrac{x{:}\tau^\star \in \Gamma \quad \Delta = \cdot}{\Gamma;\Delta \vdash x : \tau^\star}$ | **T-UVar**<br>$\dfrac{x{:}\tau \in \Gamma}{\Gamma; \cdot \vdash x : \tau}$ |
| **Delta-Empty**<br>$\cdot \uplus \cdot = \cdot$ | **U-Empty**<br>$\cdot \uplus \cdot = \cdot$ |
| **Delta-Left**<br>$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \quad x \notin \Delta}{\Delta_1, x{:}\tau^\circ \uplus \Delta_2 = \Delta, x{:}\tau^\circ}$ | **U-Left**<br>$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \quad x \notin \Delta}{\Delta_1, x{:}\tau \uplus \Delta_2 = \Delta, x{:}\tau}$ |
| **Delta-Right**<br>$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \quad x \notin \Delta}{\Delta_1 \uplus \Delta_2, x{:}\tau^\circ = \Delta, x{:}\tau^\circ}$ | **U-Right**<br>$\dfrac{\Delta_1 \uplus \Delta_2 = \Delta \quad x \notin \Delta}{\Delta_1 \uplus \Delta_2, x{:}\tau = \Delta, x{:}\tau}$ |
| **T-TAbs**<br>$\dfrac{\Gamma, \alpha{:}\kappa_1;\Delta \vdash e : \tau^{\kappa_2} \quad \alpha \notin \Gamma}{\Gamma;\Delta \vdash \Lambda \alpha{:}\kappa_1.e : \forall \alpha{:}\kappa_1.\tau}$ | **T-TLam**<br>$\dfrac{\Gamma, \alpha{:}\kappa;\Delta \vdash v : \tau \quad \alpha \notin \Gamma}{\Gamma;\Delta \vdash \Lambda \alpha{:}\kappa.v : \forall \alpha{:}\kappa.\tau}$ |
| **T-TApp**<br>$\dfrac{\Gamma;\Delta \vdash e : \forall \alpha{:}\kappa_1.\tau' \quad \Gamma \vdash \tau : \kappa_2 \quad \kappa_1{=}\kappa_2}{\Gamma;\Delta \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}$ | **T-TApp**<br>$\dfrac{\Gamma;\Delta \vdash e : \forall \alpha{:}\kappa.\tau' \quad \Gamma \vdash \tau : \kappa}{\Gamma;\Delta \vdash e[\tau] : \{\alpha \mapsto \tau\}\tau'}$ |
| **Kind-Arr**<br>$\dfrac{\Gamma \vdash \tau_1 : \kappa_1 \quad \Gamma \vdash \tau_2 : \kappa_2}{\Gamma \vdash \tau_1 \xrightarrow{\kappa_3} \tau_2 : \kappa_3}$ | **K-Arr**<br>$\dfrac{\Gamma \vdash \tau_1 : \kappa_1 \quad \Gamma \vdash \tau_2 : \kappa_2}{\Gamma \vdash \tau_1 \xrightarrow{\kappa} \tau_2 : \kappa}$ |
| **Kind-TVar**<br>$\dfrac{\alpha{:}\kappa \in \Gamma}{\Gamma \vdash \alpha : \kappa}$ | **K-TVar**<br>$\dfrac{\alpha{:}\kappa \in \Gamma}{\Gamma \vdash \alpha : \kappa}$ |
| **Kind-All**<br>$\dfrac{\Gamma, \alpha{:}\kappa_1 \vdash \tau : \kappa_2 \quad \alpha \notin \Gamma}{\Gamma \vdash \forall \alpha{:}\kappa_1.\tau : \kappa_2}$ | **K-All**<br>$\dfrac{\Gamma, \alpha{:}\kappa \vdash \tau : \kappa' \quad \alpha \notin \Gamma}{\Gamma \vdash \forall \alpha{:}\kappa.\tau : \kappa'}$ |

## Conclusion and Credits

I will write up notes for the rest of the paper too, hopefully in a week or so. 

Thanks to [Claude](https://claude.ai/) for transcribing all the type inference
rules as well as the markdown tables and checking the draft for errors in the
language.

## References

- Chapter 23 (Universal Types) in [Types and Programming
  Languages](https://www.cis.upenn.edu/~bcpierce/tapl/)

- Chapter 16 (System F of Polymorphic Types) in [Practical Foundations for Programming Languages](https://www.cs.cmu.edu/~rwh/pfpl.html)

- [A Brief History of Jigsaw Puzzles](https://artandfablepuzzlecompany.com/a-brief-history-of-jigsaw-puzzles/)
