<!-- This is the proposal that I submitted. I revised the abstract before -->
<!-- the speakers were announced. -->

# Title

Programming Robots With Elm

# Abstract

Elm is most often used to make webapps, but it's a great language for
other domains as well. Using ports and the actor model, we can embed
Elm in another environment - whether it's a larger application or just
a thin layer of glue code.

In this talk we will learn how to use Elm to program a robot. This
will involve both imperative and functional programming, and play to
the strengths of each of them.

# Details

While the main focus of Elm is on building webapps, the language can
be used for other applications as well. Most Elm applications start
with Html.program, but in this talk we'll put aside the Html library
and the virtual DOM, and start with Platform.program. This lets us run
a headless Elm application with which we can communicate via ports -
thus, the Elm application is an actor in an Actor system.

This opens up the possibility of using Elm for all sorts of
problems. I'll show a (hopefully live!) demo of using Elm to control a
LEGO Mindstorms robot. This will form the foundation for the topics
that I cover in the rest of the talk.

Programming a robot inherently involves talking to hardware. Even if
we're using a functional language, a processor is ultimately an
imperative machine. I'll talk about areas where it still makes sense
(or is required) to use an imperative languge,

I'll break down the process of programming a robot into three main
systems: perception, behaviour, and control. For each of these systems
I'll talk about how Elm can be used, show an example of how I used it
in a simple robot, and discuss its advantages and disadvantages.

Perception is about taking input from sensors and turning it into a
representation that a program can reason about. This typically
requires an imperative language to interface with sensor hardware, but
Elm can be used to filter and process the raw data into a symbolic
form.

Behaviour is about reasoning over the robot's understanding of the
world and deciding what it should do. This is an area where I think
Elm can shine the most. I'll focus on two techinques for developing a
robot's behaviour - decision trees and state machines. Both can be
elegantly described in Elm using features such as union types and
pattern matching. In some cases, the expressivity of the language is
such that an informal description of a robot's behaviour (such as "if
the front of the robot is blocked then it should stop") translates
very naturally to Elm code.

Control is all about turning the robot's intentions into actual
physical actions. Control systems are often described by mathematical
formulae that can be conveniently expressed in a functional
language. I'll show how Elm as a language is a natural fit here, but
I'll also talk about situations where one might want to use an
imperative language instead - for example, when deterministic
real-time performance is required.

By the end of the talk I aim to achieve two goals. First, I hope that
the audience will discover that although webapps and robots may look
very different there are parallels in their architecture and
implementation. Second, I would like the audience to think outside the
box in terms of the tasks for which they can use Elm.

# Pitch

I expect that the audience at elm-conf will be mostly web developers,
and that robotics is an area that they might not have thought about
much.  I feel that one of the best ways to learn is by drawing
parallels between seemingly different topics, and I hope that a
multidisciplinary talk will spark the audience's imagination.

I started playing with LEGO robotics when I was young - it was my
introduction to programming.  I'm currently employed as an Artificial
Intelligence Engineer, where I work on behaviour development for
autonomous cars.  This work draws on both functional and imperative
programming, and integrates the two in ways that play to each of their
strengths.
