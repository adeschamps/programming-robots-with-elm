---
title: Programming Robots with Elm
author: Anthony Deschamps
date: September 26, 2018
---

# Introduction

> screenshot of elm home page "a delightful language..."

The Elm home page describes it as "a delightful language", and I
really like that description because it focuses on the experience of
using it - not just the technical aspects or the end result. Now, I'm
not really a web developer. I mostly work in robotics. However, I
still really like that idea of a language being delightful, and I
wanted to answer the question "what would it be like to use Elm to
program a robot?"

I'm Anthony Deschamps. I work in robotics. Here are my credentials:

> photo from RoboFest

## LEGO Robotics

When I was 9 years old I got a LEGO robotics kit for my birthday. It
wouldn't be an understatemet to say that this was one of the most
influential moments on my life.

<!-- Quick overview of the EV3, sensors, motors, and ev3dev -->

At the time, LEGO Mindstorms used a 16 bit microcontroller, and it had
five slots for storing programs, which you uploaded to it using an
infrared transmitter. These days, it's basically a full blown computer
in a similar form factor, but the basic idea is the same. You get a
controller and a handful of motors and sensors, all wrapped up inside
LEGO bricks. It comes with software to program the robot by dragging
and dropping blocks. It's really compelling for kids of all ages,
because you can basically make a flowchart, click run, and then your
robot will *move*.

<!-- Screenshot of EV3 software -->

But the best part, at least for me, is ev3dev, which is a Debian
distribution that you can boot from a micro SD card. It provides low
level access to the sensors and motors - in true Unix fashion, they
show up as files in slash dev. There are also API bindings in various
languages. There's C and C++, of course, as well as Python, Go, and
... JavaScript!

<!-- Slide title: All the work I didn't have to do -->

So, if we can program a LEGO robot using JavaScript, and we can
compile Elm to JavaScript... you see where this is going. So much of
the hard work is already done for us. We just have to put the pieces
together.

Also, if you shut it down and take out the SD card, then it goes back
to LEGO's standard firmware, so if your kids have one of these kits,
you can play around with it without ever stepping on their toes.

> Slide

So, Elm is a language that's focused on a particular application, but...

- Can Elm be used to program a robot? (spoiler: yes)

If it couldn't then this would be a fairly short talk.

- Is it __delightful__ for robotics? (sometimes!)

- What can we learn? (what parallels with web dev?)

# Body intro

I am going to, somewhat arbitrarily, break robotics down into three
areas: perception, behaviour, and control, and map them onto the Elm
architecture we already know.  Perception is all about taking a stream
of incoming data from sensors and turning it into a form that's
convenient to reason about. Behaviour is where you say "given the
state that I'm currently in, what state do I want to be in, and how do
I get there". And control is where you take those decisions and
actually make motors move, or lights turn on. You could also think of
this as "understand the world", "decide what to do", and "act".

Now, let's see how that maps to the Elm architecture. Here's the root
of a typical Elm application:

```haskell
Html.beginnerProgram :
    { model : model
    , update : msg -> model -> model
    , view : model -> Html msg
    }
    -> Program Never model msg
```

If we break this down a bit, we can see those areas I just
described. We define a type that models the state of the world, which
in this case is the state of a web application.  We observe the
outside world by receiving messages, then we make decisions about what
the application should do in the update function. And the view
function is one of the two ways that we affect the outside world (the
other one being sending out a command).

So, let's define our own version for robots. Under the hood it'll be
implemented a bit differently, but we'll keep the same basic
interface. The main difference is that the input and output are
concrete types, because they're dictated by the actual, physical
robot. Input is a record of the current values of all the sensors, and
instead of rendering Html in your view function, you "render" the
desired speed or state of your motors.

```haskell
Robot.program :
    { init : state
    , update : Input -> state -> state
    , output : Input -> state -> Output
    }
    -> Robot state

type alias Input =
    { lightSensor : Float
    , distanceSensor : Float
    -- ...
    }

type alias Output =
    { leftMotor : Float
    , rightMotor : Float
    -- ...
    }
```

# A simple robot

Before getting into how this is implemented under the hood, let's take
a look at how it feels to use it for something simple. We'll make our
robot follow a line, and not crash into things.

<!-- Insert diagram of line following -->

So, here's the basic algorithm to follow a line. We actually want to
follow the edge of the line. If the sensor reads dark, then we drive
one motor, which causes the robot to move forward and also turn
towards the white side. If the sensor reads bright, then we drive the
other motor, which causes the robot to turn towards the dark side. So
the result is that we sort of zig zag and progress forward.

<!-- Possibly insert gif of Shaq shimmying, which is an accurate -->
<!-- demonstration of this algorithm in practice. -->

Here's what the code looks like. The state of our robot can be either
blocked or unblocked.

```haskell
type State
    = Blocked
    | Unblocked
```

... if the distance sensor tells us there's something closer than 50
centimeters, then it goes into the blocked state, otherwise it goes to
the unblocked state.

```haskell
update : Input -> State -> State
update input state =
    if input.distanceSensor < 50 then
        Blocked

    else
        Unblocked
```

... and then if the robot is blocked, then it tells the motors to
stop, and if it's unblocked then it sets the motor speeds to values
that are proportional to the intensity that the light sensor reads.

```haskell
output : Input -> State -> Output
output input state =
    case state of
        Blocked ->
            { leftMotor = 0
            , rightMotor = 0
            }

        Unblocked ->
            { leftMotor = input.lightSensor
            , rightMotor = 1.0 - input.lightSensor
            }
```

This feels like a reasonably nice way to describe a robot's
behaviour. It's largely declarative, so it's easy to see what the
robot will do in a given situation. And the stateful parts of it are
clearly delineated. So let's see how this works.

<!-- Run the robot -->

# Wiring this up

The code to wire all this up is actually quite simple. Most of the
hard work has already been done by the ev3dev project. On the
JavaScript side we set a timer. Every so often, we use the ev3dev APIs
to read the sensors, then we bundle up all the readings into an object
and send it through a port. The Elm app subscribes to that port. Every
time it gets new inputs, it runs the `update` function, then it calls
the `output` function and sends the result back to JavaScript through
the `outputs` port. JavaScript takes that command and uses the ev3dev
APIs to set motor speeds. And that's about it.

<!-- I'm not sure how much code to show here. -->

```haskell
type alias Input =
    { -- ...
    }

port inputs : (Input -> msg) -> Sub msg

update config msg model =
    case msg of
        NewInput input ->
            let newState = config.update input model.state
                output = config.output input newState
            in ( { model | state = newState }, outputs output )
```

```js
setInterval(updateInput, 50);

function updateInput () {
    const inputs = { /* ... */ };
    app.ports.inputs.send(inputs);
}
```

```haskell
type alias Output =
    { -- ...
    }

port outputs : Output -> Cmd msg
```

```js
app.ports.outputs.subscribe(handleOutputs);

function handleOutputs(outputs) {
    /* ... */
}
```

# Taking this further

One of the things I enjoyed about using Elm is, of course, the type
system. In some cases, that just means mapping raw input to values
that are more semantically meaningful. For example, the update
function contains this code, which looks at the value of the touch
sensor, which is a boolean, and turns it into a value of a new type,
which can be "Pressed" or "Unpressed".

<!-- Refer to "Solving the Boolean Identity Crisis" -->

```haskell
type Bumper = Pressed | Unpressed

updateState : Input -> State -> State
updateState input state =
    let
        bumper =
            if input.touchSensor then
                Bumper.Pressed

            else
                Bumper.Unpressed
    in
    { state | bumper = bumper }
```

A little later, in the function that decides what the robot's current
goal is, I use the value of the bumper to decide that we need to go
from "searching" to "grabbing the object".

```haskell
updateGoal : State -> Goal -> Goal
updateGoal state goal =
    case goal of
        Search ->
            if state.bumper == Bumper.Pressed then
                GrabObject
        {- ... -}
```

One of the goals I strive for, particularly when it comes to decision
making logic, is that reading the code should be as similar as
possible to what you would say if you were describing the logic to
somebody. I think this reads pretty nicely - "when our current goal is
`Search`, if the bumper is `Pressed`, the our new goal is to
`GrabObject`".

# Downsides

I don't think it would be fair to go through all this and not talk
about the downsides. What are some reasons why you _wouldn't_ want to
program a robot in Elm?

One of the main difficulties I encountered was to do with
performance. This isn't an issue with Elm as a language, per se, but
it is a fairly heavy software stack to run on this hardware. This is a
single core processor running at 300 MHz. To put that in perspective,
it takes about five to ten seconds for node.js to start up on this
device.

In order for the robot to be responsive it needs to be able to read
inputs, make decisions, and produce an output - _reliably_ - at a rate
on the order of tens of milliseconds. That means that any time node.js
stops to do a garbage collection - which might take a bit of time on
this hardware - the robot just becomes unresponsive until its
finished, and by that time it may have lost track of its route.

It definitely doesn't help that I'm sending data over the network to
visualize it. With a single core processor, that means that any time
doing an HTTP POST is time _not_ spent reading the sensors.

The bottom line is this - if you want to build a real time system
targeting low end hardware, any language with a garbage collector is
going to create some challenges for you.

That said, my original goal was to explore whether Elm is a nice
_language_ for robots. Whether Elm compiled to JavaScript running on
Node is a nice _platform_ - that's somewhat besides the point. But I
think the takeaway is that if you want to put Elm on a robot you might
need more powerful hardware.

# Wrapping up

Going back to the questions we originally set out to answer,

- Can Elm be used to program robots?

Yes, it can.

- Is it an effective language for robots?

I would say yes. Everything that I tried to do, I was able to do
without resorting to any hacks. I could imagine things could get
challenging if you were dealing with hardware that can't run
JavaScript, or if you need libraries that don't work with Elm. But for
what I was doing here, I think it worked well.

- Is it delightful?

That's subjective. I can speak for myself, that I enjoyed it. I think
that Elm made it easy to model the different states that a robot can
be in, and I think the declarative nature of Elm made it easy to
understand why a particular state results in a particular output. If
anything, it was fun to explore, and to do something a little
unconventional. I would encourage you to take a look at the code, and
if this is an approach that resonates with you, go and explore!

I'd like to thank Matt Griffith for mentoring me through my first
conference talk, as well as Mike Onslow and the rest of the Elm
Detroit Meetup group for their helpful feedback.

My slides are available online. You can reach my on Slack or by email,
and I'd love to talk to you. Thank you!
