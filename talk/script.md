- When I was 9 years old I got a LEGO robotics kit
- Insert picture from Robofest
- So this is me, a couple of years ago.

I'm Anthony Deschamps. I work in robotics. Here are my credentials <photo from robofest>.

- How many people grew up with lego robots / have kids who play with them?




<screenshot of elm home page "delightful language...">

The Elm home page describes it as "a delightful language", and I
really like that description because it focuses on the experience of
using it - not just the end result. Now, I'm not really a web
developer. I mostly work in robotics. However, I still really like
that idea of a language being delightful, and I wanted to answer the
question "what would it be like to use Elm to program a robot?"

<!-- End introduction -->

# Slide

So, Elm is a language that's focused on a particular application, but...

- Can Elm be used to program a robot? (spoiler: yes)

If it couldn't then this would be a fairly short talk.


- Is it __delightful__ for robotics? (sometimes!)

- What can we learn? (what parallels with web dev?)


# EV3

<!-- Quick overview of the EV3, sensors, motors, and ev3dev -->

# Body intro

I am going to, somewhat arbitrarily, break robotics down into three
areas: perception, behaviour, and control.  Perception is all about
taking a stream of incoming data from sensors and turning it into a
form that's convenient to reason about. Behaviour is where you say
"given the state that I'm currently in, what state do I want to be in,
and how do I get there". And control is where you take those decisions
and actually make motors move, or lights turn on. You could also think
of this as "understand the world", "decide what to do", and "act".

Now, let's see how that maps to the Elm architecture. Here's the root
of a typical Elm application:

```elm
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

```elm
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

```elm
type State
    = Blocked
    | Unblocked
```

... if the distance sensor tells us there's something closer than 50
centimeters, then it goes into the blocked state, otherwise it goes to
the unblocked state.

```elm
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

```elm
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
clearly delineated. And it works.

<!-- Run the robot -->

# Wiring this up



...





# Can it be used for robotics
