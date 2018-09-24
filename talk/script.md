---
title: Programming Robots with Elm
author: Anthony Deschamps
date: September 26, 2018
---

# Introduction

> Slide: Screenshot of the Elm home page: "a delightful language..."

The Elm home page describes it as "a delightful language", and I
really like that description because it focuses on the experience of
using it - not just the technical aspects or the end result. But it
specifically describes it as a language for webapps, which makes me
wonder: is Elm a delightful language for other applications as well?

I'm Anthony Deschamps. I like robots. Here are my credentials:

> Slide: photo from RoboFest when I was 12

## LEGO Robotics

When I was 9 years old I got a LEGO robotics kit for my birthday. It
wouldn't be an understatement to say that this was one of the most
influential moments on my life.

<!-- Quick overview of the EV3, sensors, motors, and ev3dev -->

At the time, LEGO Mindstorms used a 16 bit microcontroller, and it had
five slots for storing programs, which you uploaded to it using an
infrared transmitter that was plugged in to the serial port on your
computer. These days, it's basically a full blown computer in a
similar form factor, but the basic idea is the same. You get a
controller and a handful of motors and sensors, all wrapped up inside
LEGO bricks. It comes with software to program the robot by dragging
and dropping blocks. It's really compelling for kids of all ages,
because you can basically make a flowchart, click run, and then your
robot will *move*.

> Screenshot: EV3 software - programming robots with flowcharts
> [(Example)](http://encuentrocomicsevilla.com/wp-content/uploads/2017/04/Lego-Ev3-Software-Home.png)

## ev3dev

But the best part, at least for me, is ev3dev, which is a Debian
distribution that you can boot from a micro SD card. It provides low
level access to the sensors and motors - in true Unix fashion, they
show up as files in slash dev. There are also API bindings in various
languages. There's C and C++, of course, as well as Python, Go, and
... JavaScript!

So, if we can program a LEGO robot using JavaScript, and we can
compile Elm to JavaScript... you see where this is going. So much of
the hard work is already done for us. We just have to put the pieces
together.

Also, if you shut it down and take out the SD card, then it goes back
to LEGO's standard firmware, so if your kids have one of these kits,
you can play around with it without ever stepping on their toes.

## End of introduction

So, Elm is a language that's focused on a particular application, but...

- Can Elm be used to program a robot? (spoiler: yes)

If it couldn't then this would be a fairly short talk.

- Is in an **effective** language for robotics?

- Is it a **delightful** language for robotics?

And along the way, we'll see what we can learn, and maybe draw some
parallels with web development.

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
Browser.sandbox :
    { init : model
    , update : msg -> model -> model
    , view : model -> Html msg
    }
    -> Program () model msg
```

If we break this down a bit, we can see those areas I just
described. We define a type that models the state of the world, which
in this case is the state of a web application.  We observe the
outside world by receiving messages, then we make decisions about what
the application should do in the update function. And the view
function is the primary way that we affect the outside world. Even
though Elm is a pure language, we still have this one giant side
effect - it's kept in one place, and the actual effects are performed
by the Elm runtime.

So, let's define our own version for robots. Under the hood it'll be
implemented a bit differently, but we'll keep the same basic
interface.

```haskell
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

Robot.program :
    { init : state
    , update : Input -> state -> state
    , output : Input -> state -> Output
    }
    -> Robot state
```

We have an `init` function, just like we're used to, except I haven't
exposed anything to do with commands because our robot isn't going to
need them.

Our `update` function is the same, except instead of defining a
message type we have a concrete type for `Input`, because that's
dictated by the actual, physical hardware. It's a record of the
current values of all the sensors that are plugged in. We'll set this
up so that the `update` function gets called every time there's new
sensor inputs available.

Instead of a `view` function, we have an `output` function. Rather
than render HTML to affect the world, we "render" the desired speed or
state of each of our motors. So whereas a typical Elm app has a
declarative view, so that what you see on the page always reflects the
model, our robot has declarative outputs, so that what it's doing
always reflects its internal state and its inputs.

# A simple robot

Before getting into how this is implemented under the hood, let's take
a look at how it feels to use it for something simple. We'll make our
robot follow a line, and not crash into things.

Our robot has a light sensor that points at the ground. It has an LED
that illuminates a surface, and a photosensor that measures the
intensity of the light that was reflected. It gives us a percentage,
where 0% means really dark and 100% means really bright.

We also have an ultrasonic distance sensor on the front. It emits a
high pitched sound called a chirp and then measures how long it takes
for the sound to be reflected back, just like a bat. If you've driven
a car that beeps when you're about to back into an object, this is
basically how it works. This sensor gives a measurement between 0 and
255 centimeters.

> Diagram: line following algorithm

So, here's the basic algorithm to follow a line. We actually want to
follow the edge of the line. If the sensor reads dark, then we drive
one motor, which causes the robot to move forward and also turn
towards the white side. If the sensor reads bright, then we drive the
other motor, which causes the robot to turn towards the dark side. So
the result is that we sort of zig zag and progress forward.

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

> Run the robot!

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

> TODO: I'm not sure how much code to show here.

```haskell
-- Subscribe to inputs, update state, and send outputs
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
// Read sensors and send through ports
setInterval(updateInput, 50);

function updateInput () {
    const inputs = { /* ... */ };
    app.ports.inputs.send(inputs);
}
```

```haskell
-- Send outputs through port
type alias Output =
    { -- ...
    }

port outputs : Output -> Cmd msg
```

```js
// Subscribe to outputs and set motor speeds
app.ports.outputs.subscribe(handleOutputs);

function handleOutputs(outputs) {
    /* ... */
}
```

# Taking this further

Going back to the breakdown of robotics into perception, behaviour,
and control, the line following robot is about the simplest thing I
could think of that covers all three. We have two inputs, one which we
map from a numeric to a more meaningful symbolic value. That's
perception. We have a simple behaviour, which is to decide whether to
go or stop. And then we have a simple controller to follow the line.

Now I want to dig a bit deeper into each of these areas and see how
Elm fares when we push it a little further to do something more
complicated.

So let's come up with a challenge for ourselves!

My guiding criteria here was to come up with something that's
complicated enough to give us something interesting to talk about, but
not so complicated that we can't cover it in this presentation. So
let's make a robot that can:

- Follow a line around this oval track
- When it bumps into an object, grab it and move it off the track
- Always push objects _outside_ the oval

This is actually a pretty good start for a grade school level robotics
challenge. The competitions that I was in as a kid were a bit more
challenging, but we also had about four months to prepare. And we
didn't have Elm, so it took longer.

Of course, if this was _actually_ a grade school robotics challenge,
then there would be a fun story to set up this scenario.

## Perception

As far as perception goes, we have two new problems on top of
following the line. The first is that we need to know when we've
encountered an obstacle, and the second is that we need to know which
side of the line is the outside of the track.

The first one is easy. We have a touch sensor on the front of the
robot. When this bumper is pressed it returns true, and when it's not
pressed it returns false.

<!-- Move relevant content from the behaviour section to here -->

The second one is tricky. We should be able to tell where we are by
paying attention to the curvature of the track, but we don't have a
sensor that measures that. What we can do is measure how much each
wheel turns, and if one wheel is turning more than the other then we
know that the robot is turning.

Each motor has an odometer in it that measures how many degrees it's
turned. Each time the update function is called, we can measure how
much each wheel turned and take the difference between the left and
right wheels. So if the robot is going straight, then the difference
should be close to zero. If it's positive then it means it's curving
to the right, and if it's negative then it's curving to the left.

If we plot this value over time as the robot runs, then we basically
get a big old mess, because the robot is constantly adjusting itself
as it follows the line.

> Plot of instantaneous (deltaLeft - deltaRight), which is very noisy

At first glance it doesn't look like there's any information here, but
if we calculate a moving average then we start to see a pattern.

> Plot of exponentially smoothed (deltaLeft - deltaRight), which can
> resolve curvature.

```haskell
instant =
    if totalTravel > 0 then
        delta / totalTravel

    else
        0.0

average_1_0 =
    let
        alpha =
            1.0 - e ^ (-totalTravel / 1.0)
    in
    state.average_1_0 * (1 - alpha) + instant * alpha
```

This is an exponential moving average. Each time we update, we adjust
the average towards the currently observed value according to some
coefficient. In this case, the coefficient is a function of the
distance we've travelled since the last update - that's to ensure that
the calculation isn't affected by the speed of the robot. Also, we can
play with the coefficient and get different curves. If we put more
weight towards the most recent value then the average is noisier but
reacts more quickly, and if we put less weight on the most recent
value then we get a nice smooth curve, but it responds to changes more
slowly.

With a bit of experimentation, we can pick a nice coefficient and then
some thresholds, and then we can turn this stream of numbers into a
symbolic, qualitative value of `Left`, `Straight`, or `Right`. Each
update we match on the current qualitative value and if the raw
numeric curvature is over a threshold, then we switch states. Notice
that the thresholds are different depending on the direction of the
transition. Otherwise, a bit of noise in the raw values can cause us
to flip back and forth between states if we happen to be near the
boundary.

```haskell
type Curve
    = Straight
    | Left
    | Right

calculateCurve : Float -> Curve -> Curve
calculateCurve curvature current =
    case current of
        Left ->
            if curvature > -0.2 then
                Straight

            else
                current

        Straight ->
            if curvature < -0.25 then
                Left

            else if curvature > 0.25 then
                Right

            else
                current

        Right ->
            if curvature < 0.2 then
                Straight

            else
                current
```

When I first wrote that function I felt like it was kind of _big_, or
spread out, and I tried to refactor it to make it more compact. But
other than the fact that elm-format puts a generous amount of
whitespace in there, I realized that this function says exactly what it
needs to and no more. So I decided to stop worrying about it.

What we're essentially doing here is taking data from one type of
sensor and inferring new information that we can't directly
measure. That's what perception is all about - taking raw measurements
and turning them into more meaningful information.

<!-- Add some Elm specific thoughts -->

## Behaviour

Something I enjoy about Elm is using the type system to model the
different states my programs can be in. In some cases, that just means
mapping raw input to values that are more semantically meaningful. For
example, the update function contains this code, which looks at the
value of the touch sensor, which is a boolean, and turns it into a
value of a new type, which can be "Pressed" or "Unpressed".

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

> NOTE: I feel like the above paragraphs should be moved towards the
> middle/end of this section.

It's important that the behaviour logic be easy to read and
understand, because once we start to consider all the states that the
robot can be in, we find that it's a bit trickier than you might have
thought. There are some transitions between states that we don't want
to make.

This sounds a bit like one of those "make impossible states
impossible" situations. In some ways it is, but it's also a problem of
making impossible _transitions_ impossible.

> NOTE: It's possible to prevent invalid transitions using the type
> system, but I don't think it's worth the effort and complexity
> here. Instead, I want to tackle the problem by making transitions
> between states simple to express and therefore simple to look at and
> verify.

For example, when the robot finds an object, it'll need to go through
some maneuvers to grab it, move off of the path, let it go, and then
return to the path. We definitely don't want to go back into the
`Search` state right after letting go of the object, because at that
moment there's no line to follow.

> TODO: Finish designing the behaviour state machine
>
> ```haskell
> type Goal
>     = Initialize
>     | Search
>     | GrabObject
>     | MoveObject
> ```

> NOTE: Encoding sequential behaviours in a functional language can
> actually be a bit awkward until you crack it.


## Control

The third area ef robotics that I mentioned, control, is something
we've already talked about. The line following algorithm I described
is an example of a proportional controller, or P controller. This is
where you have value that you're measuring, as well as a target value,
called a set-point. If you take the difference between your current
measurement and your desired value, that's your error. Then you set
your output value to be proportional to the error.

In the case of our line follower, the light sensor is our input, and
our set-point, or target, is for the sensor to be on the edge of the
line. So we set the speeds of our motors to values that are
proportional to the current reading of the light sensor.

Not all controllers are that simple. P controllers are a simpler case
of the more general PID controller. If you want to know more about
that, find the nearest mechanical or electrical engineer - they'll be
able to tell you all about control theory.

The common thread in control theory is that you have some output which
is a function of your inputs - which is really easy to express in a
functional languge - but sometimes your output also depends on some
internal state. We sort of saw an example of that when measuring the
curvature of the line. The output value depends not just on the
current inputs, but also on a running average.

The thing about controls is that these simple control algorithms tend
to get composed together into more complicated controllers. It's
common to ask questions like "why isn't the system doing what I'm
telling it to do?" Your decision making code might have decided that
the vehicle should drive at a certain speed, but there are multiple
levels of controllers between it and the actual motors. At each level,
there might be a bit of state, and although individually they're quite
simple, it can be hard to keep track of.

> NOTE: I feel like the last few paragraphs are rather meandering and
> not really that interesting in relation to Elm.

Another place where Elm's type system is useful is in constraining the
types of output that are valid. We have a robot with three motors on
it. Two of them are for driving and the third is for grabbing
things. Let's say we decide that the claws should only open or close
if the robot isn't moving.

The `Output` record we defined earlier is a direct, one-to-one
interface to the motors, but we can define a custom type that makes
controlling the claw and controlling the wheels mutually exclusive.

```haskell
-- This code will probably change a bit.

type ClawAction
    = ClawOpen
    | ClawClosed

type Action
    = Claw ClawAction
    | Wheels { left : Float, right : Float }

output : Action -> Output
output action =
    case action of
        Claw claw ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor =
                case claw of
                    ClawOpen ->
                        1.0

                    ClawClosed ->
                        -1.0
            }

        Wheels { left, right } ->
            { leftMotor = left
            , rightMotor = right
            , clawMotor = 0.0
            }
```

# Conclusion

Going back to the questions we originally set out to answer,

- Can Elm be used to program a robot?

Yes - we have a robot, we put Elm on it, and it did something.

- Is it an **effective** language for robotics?

There are actually two questions here that could easily be conflated.

- Is it an effective **language** for robotics?
- Is it an effective **platform** for robotics?

## Downsides

Well, there are some reasons why you _wouldn't_ want to program a
robot in Elm?

One of the main difficulties I encountered was to do with
performance. This isn't an issue with Elm as a language, per se, but
it is a fairly heavy software stack to run on this hardware. This is a
single core processor running at 300 MHz. To put that in perspective,
it takes about five to ten seconds just for node.js to start up on
this device.

In order for the robot to be responsive it needs to be able to read
inputs, make decisions, and produce an output - _reliably_ - at a rate
on the order of tens of milliseconds. That means that any time node.js
stops to do a garbage collection - which might take a bit of time on
this hardware - the robot just becomes unresponsive until it's
finished, and by that time it may have lost track of its route.

It definitely doesn't help that I'm sending data over the network to
visualize it. With a single core processor, that means that any time
doing an HTTP POST is time _not_ spent reading the sensors. So there's
surely room to optimize things, but the bottom line is this - if you
want to build a real time system targeting low end hardware, any
language with a garbage collector is going to create some challenges
for you.

That said, my original goal was to explore whether Elm is an effective
_language_ for robots. Whether Elm compiled to JavaScript running on
Node is an effective _platform_ - that's somewhat beside the
point. But I think the takeaway is that if you want to put Elm on a
robot you might need more powerful hardware.

## Upsides

So is Elm an effective _language_ for robotics?

I would say yes. Everything that I tried to do, I was able to do
without resorting to any hacks. I imagine things could get challenging
if you were dealing with hardware that can't run JavaScript, or if you
need libraries that don't work with Elm. But for what I was doing
here, I think it worked well.

> Slide: summarize the following as bullet points

Perception often involves some amount of state, and a pure language
makes your inputs and state explicit. A lot of behaviour can be
naturally expressed as state machines, and pattern matching with
custom types is great for that. And a declarative approach to motor
control has all the same benefits as a declarative approach to views.

But the most important question I wanted to answer was...

- Is it a **delightful** langugae for robotics?

That's subjective, but I can speak for myself - I enjoyed it! I spent
most of my time thinking about the problem, not the code. If anything,
it was fun to explore, and to do something a little unconventional. I
would encourage you to take a look at the code, and if this is an
approach that resonates with you, go and explore!

## Wrapping up

And with that said, I'd like to thank Matt Griffith for mentoring me
through my first conference talk, as well as Mike Onslow and the rest
of the Elm Detroit Meetup group for their helpful feedback.

My slides are available online. You can reach me on Slack or by email,
and I'd love to talk to you. Thank you!
