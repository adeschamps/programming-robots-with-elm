# Outline

How do languages describe themselves?

Most focus on what they are or what they achieve.  Elm is an outlier
in that its description, "a delightful language for reliable webapps",
emphasizes the experience of using it. (Ruby also falls into this
category, describing itself as "a programmer's best friend").

So, Elm is a language that's focused on a particular application, but...

- Can it be used for other applications? (spoiler, yes)
- Can it be used for robotics? (yes)
- Is it __delightful__ for robotics? (sometimes!)
- What can we learn? (what parallels with web dev?)

# How to put Elm in a LEGO robot

(subtitle: all the hard work I didn't have to do myself)

- Brief description of the Mindstorms EV3 (specs, inputs, outputs)
- ev3-dev, the Debian distribution for the EV3
- nodejs bindings
- Wiring up Elm <-> node <-> robot using ports

# Aspects of robotics

Break down the problem of programming a robot into three main systems:

- Perception (sensors to internal model)
- Behaviour (internal model to decisions)
- Control (decisions to outputs)

A decent chunk of the talk will be working through an example of each
of these, and show how it can be implemented with Elm.

# Simple Control

Start with control, because this is what makes a robot move and
therefore is an exciting demo.

Line follower:
- Perception is trivial (just need raw sensor values)
- Behaviour is trivial (only one state - follow line)
- Control is a basic P controller

We may come back to a more complicated example of control (with a PID
controller), if there's enough time.

# Simple Perception and Behaviour

Stop for obstacle:
- Perception is still simple - distance sensor is either blocked or open.
- Behaviour is simple - two states, hold and follow, directly based on perception.
- Control is basically the same, but branches based on the state.

# Build up to more complicated robot

I'm not sure what direction I want to go yet. Options include:

- Object follower using panning ultrasonic sensor

  Sample distance at many angles, filter raw input, implement some
  kind of edge/object detection, and behaviour to follow an object.

  This is heavy on perception, but fairly simple on behaviour and
  control.

- Sorting robot with a claw/grabber

  Either follow a path or use ultrasonic to find objects, move towards
  them, pick them up, and sort them based on colour.

  Less heavy on perception (although there's still some), but much
  more interesting behaviour - can lead into a discussion of state
  machines.

  Controls are still simple, but a bit more interesting, since it
  includes another motor.

# Discuss pros and cons of using Elm

In perception:
- Elm can work well for simple perception, but is probably the wrong
  choice for more complex perception.
- Elm is fine for everything we do in this demo.
- If we were doing some kind of image processing or vision, then
  imperative languages that give control over memory are often
  better. (also, there are existing libraries and algorithms to
  leverage)

  Optimization is about understanding how things work under the hood,
  and catering to them.

  Comparison: In functional programming, we sometimes think about tail
  call optimizations. In doing so, our mind and reasoning has skipped
  over multiple layers of abstraction. Rather than think about how a
  compiler will optimize our code, sometimes we just need to use a low
  level language so we can be sure of the result.

Behaviour:
- Elm works well here.
- Decision trees can be expressed naturally. A naive implementation
  may not be the most efficient, but it's not going to be a bottleneck
  and is not worth worrying about here.
- Expressing state machines is pleasant, and it's easy to reason about
  why the robot is acting the way it is given its understanding of the
  world.

Control:
- For stateless controls, such as the P controller for line following,
  functional is an obvious fit.
- For stateful controllers (if we talk about them) it can help us keep
  implicit state in check.
- Lack of side effects helps us manage situations where there is
  contention or conflicts among outputs (we may run into this with a
  grabber - the robot shouldn't be driving while the claw is
  opening/closing)
- If our robot had realtime requirements, then controls might have to
  be move into embedded systems. Elm is no the right choice here, but
  it satisfies the soft realtime requirements of our demo.

# Summary

Revisit original questions:

- Can Elm be used in a robot?
  Yes - include links to resources

- Is it delightful?
  - For perception - yes for simple cases, no for more CPU/memory intensive work
  - For behaviour - yes, and this is where it's most similar to webapps (think about valid states and transitions between them)
  - For controls - yes, as long as it's not a bottleneck, although the hardware/architecture is more likely to be a bottleneck first.
