module mar.time;

import mar.passfail;


/**
A timestamp with a resolution of 1 microsecond or better.
For windows this uses QueryPerformanceCounter.
*/
struct UsecTick
{
    version (Windows)
    {
        private long value;
    }
    else
    {
        static assert(0, "not implemented on this platform");
    }

    passfail update()
    {
        version (Windows)
        {
            pragma(inline, true);
            import mar.windows.kernel32 : QueryPerformanceCounter;
            if (QueryPerformanceCounter(&value).failed)
                return passfail.fail;
            return passfail.pass;
        }
    }

}


/+



version(Windows)
{
    import core.sys.windows.windows :
        GetLastError,
        LARGE_INTEGER,
        QueryPerformanceFrequency, QueryPerformanceCounter;
    private immutable long performanceFrequency;
    static this()
    {
        {
            LARGE_INTEGER temp;
            if (!QueryPerformanceFrequency(&temp))
            {
                import std.format : format;
                throw new Exception(format("QueryPeformanceFrequency failed (e=%d)", GetLastError()));
            }
            performanceFrequency = temp.QuadPart;
        }
    }
}

version (Windows)
{
    pragma(inline) auto ticksPerSecond() { return performanceFrequency; }
}
else version (Posix)
{
    // FOR NOW: we are just going to represent posix ticks as microseconds
    enum ticksPerSecond = 1000000; // assume nanosecond for now
}

enum TimeUnit : byte
{
    seconds      =   0, // 10 ^ 0
    deciseconds  =  -1, // 10 ^ -1
    centiseconds =  -2, // 10 ^ -2
    milliseconds =  -3, // 10 ^ -3
    microseconds =  -6, // 10 ^ -6
    nanoseconds  =  -9, // 10 ^ -9
    picoseconds  = -12, // 10 ^ -12
}
string inverseMultiplierMixin(TimeUnit unit) pure
{
    final switch(unit)
    {
        case TimeUnit.seconds:      return "1";
        case TimeUnit.deciseconds:  return "10";
        case TimeUnit.centiseconds: return "100";
        case TimeUnit.milliseconds: return "1000";
        case TimeUnit.microseconds: return "1000000";
        case TimeUnit.nanoseconds:  return "1000000000";
        case TimeUnit.picoseconds:  return "1000000000000";
    }
}

struct Duration(TimeUnit timeUnit, T)
{
    private T value;
    void reset() { this.value = cast(T)0; }
    mixin OpUnary!("value");
    mixin OpBinary!("value", No.includeWrappedType);
    mixin OpCmpIntegral!("value", No.includeWrappedType);
    auto to(TimeUnit unit)() const
    {
        assert(0, "not implemented");
        //return value * mixin(unit.inverseMultiplierMixin) / ticksPerSecond;
    }
    T to(TimeUnit unit, T)() const
    {
        assert(0, "not implemented");
        /+
        const result = durationTicks * mixin(unit.inverseMultiplierMixin) / performanceFrequency;
        static if (T.sizeof < result.sizeof)
        {
            if ((cast(typeof(result))T.max) < result)
            {
                import std.format : format;
                throw new Exception(format("time value %s is too large to be represented as type %s", result, T.stringof));
            }
        }
        return cast(T)result;
        +/
    }
}


version (Windows)
{
    //private struct DefaultTimePolicy { }
    //mixin TimeTemplate!DefaultTimePolicy { }
}
else
{
}

mixin template TimeTemplate(Policy)
{

    // TODO: make this configurable through the policy somehow
    alias TimestampInteger = long;

    /**
    Contains code related to ticks.
    */
    struct Ticks
    {
        /**
        Return the number of units per 1 tick.
        */
        static DurationTicks unitsPerTick(TimeUnit unit)() pure
        {
            return DurationTicks(ticksPerSecond * mixin(unit.inverseMultiplierMixin));
        }
        /**
        Return the number ticks for 1 unit.
        */
        static DurationTicks per(TimeUnit unit)() pure
        {
            return DurationTicks(ticksPerSecond / mixin(unit.inverseMultiplierMixin));
        }
    }

    /**
    A `Timestamp` is an integer value that can roll.  Timestamps are compared
    by finding the shorter distance between 2 values.
    */
    struct TimestampTicks
    {
        private TimestampInteger ticks;

        TimestampTicks offsetWith(const DurationTicks duration) const
        {
            return TimestampTicks(this.ticks + duration.durationTicks);
        }
        DurationTicks diff(const TimestampTicks rhs) const
        {
            return DurationTicks(this.ticks - rhs.ticks);
        }
        int opCmp(const TimestampTicks rhs) const
        {
            const result = this.ticks - rhs.ticks;
            if (result < 0) return -1;
            if (result > 0) return 1;
            return 0;
        }
        /**
        Get a timestamp for the current time right `now`.
        */
        static TimestampTicks now()
        {
            version (Windows)
            {
                static assert(is (TimestampInteger == long));
                LARGE_INTEGER ticksInteger;
                if (!QueryPerformanceCounter(&ticksInteger))
                {
                    import std.format : format;
                    throw new Exception(format("QueryPerformanceCounter failed (e=%d)", GetLastError()));
                }
                return TimestampTicks(ticksInteger.QuadPart);
            }
            else version (Posix)
            {
                import core.stdc.errno : errno;
                import core.sys.posix.time : clock_gettime, timespec;
                import core.sys.linux.time : CLOCK_MONOTONIC_RAW;
                timespec now;
                if (0 != clock_gettime(CLOCK_MONOTONIC_RAW, &now))
                {
                    import std.format : format;
                    throw new Exception(format("clock_gettime with CLOCK_MONOTONIC_RAW failed (e=%d)", errno));
                }
                // TODO: detect overflow
                return TimestampTicks((cast(TimestampInteger)now.tv_sec * ticksPerSecond) +
                                      (now.tv_nsec * ticksPerSecond / 1000000000));
            }
        }
    }
    unittest
    {
        static void testAt(TimestampInteger value)
        {
            const valueTimestamp = TimestampTicks(value);
            assert(valueTimestamp == valueTimestamp);
            assert(valueTimestamp <= valueTimestamp);
            assert(valueTimestamp >= valueTimestamp);
            assert(valueTimestamp < TimestampTicks(value + 1));
            assert(valueTimestamp > TimestampTicks(value - 1));
            assert(valueTimestamp < TimestampTicks(value + (TimestampInteger.max / 6)));
            assert(valueTimestamp > TimestampTicks(value - (TimestampInteger.max / 6)));
        }
         // TODO: only do these ones if TimestampInteger is signed
        {
            testAt(TimestampInteger.min);
            testAt(TimestampInteger.min / 2);
            testAt(-1);
        }
        testAt(0);
        testAt(1);
        testAt(TimestampInteger.max / 2);
        testAt(TimestampInteger.max);
    }

    /*
    TODO: probably just be an alias to Duration!(TimeUnit.ticks, TimestampInteger).
    */
    /**
    TODO: we may want a signed/unsigned duration.
    */
    struct DurationTicks
    {
        TimestampInteger durationTicks;

        mixin OpUnary!("durationTicks");
        mixin OpBinary!("durationTicks", Yes.includeWrappedType);
        mixin OpCmpIntegral!("durationTicks", Yes.includeWrappedType);
        auto to(TimeUnit unit)() const
        {
            return durationTicks * mixin(unit.inverseMultiplierMixin) / ticksPerSecond;
        }
        T to(TimeUnit unit, T)() const
        {
            const result = durationTicks * mixin(unit.inverseMultiplierMixin) / ticksPerSecond;
            static if (T.sizeof < result.sizeof)
            {
                if ((cast(typeof(result))T.max) < result)
                {
                    import std.format : format;
                    throw new Exception(format("time value %s is too large to be represented as type %s", result, T.stringof));
                }
            }
            return cast(T)result;
        }
    }
    unittest
    {
        static void testAt(DurationTicks value)
        {
            assert(value == value);
            assert(value <= value);
            assert(value >= value);
            assert(value < value + 1);
            assert(value > value - 1);
            assert(value < value + (TimestampInteger.max / 6));
            assert(value > value - (TimestampInteger.max / 6));
        }
         // TODO: only do these ones if TimestampInteger is signed
        {
            testAt(DurationTicks(TimestampInteger.min));
            testAt(DurationTicks(TimestampInteger.min / 2));
            testAt(DurationTicks(-1));
        }
        testAt(DurationTicks(0));
        testAt(DurationTicks(1));
        testAt(DurationTicks(TimestampInteger.max / 2));
        testAt(DurationTicks(TimestampInteger.max));
    }

    /**
    Used to track "laps" of time, where each call to `lap` will return the time
    since the last call to `lap`.
    */
    struct LapTimerTicks
    {
        import more.types : unconst;

        private TimestampTicks startLapTime;

        /**
        Get the current lap start time.
        */
        TimestampTicks getStartLapTime() const
        {
            return startLapTime.unconst;
        }
        /**
        Set a custom value for the lap start time.
        */
        void setStartLapTime(TimestampTicks startLapTime)
        {
            this.startLapTime = startLapTime;
        }
        /**
        Change the lap start time.
        */
        void moveLapStartTime(DurationTicks duration)
        {
            this.startLapTime = this.startLapTime.offsetWith(duration);
        }
        /**
        Start the next lap.  This will get the current time and set it so that the next
        call to lap will take the difference between the new time with the time this was called.
        */
        void start()
        {
            startLapTime = TimestampTicks.now();
        }
        /**
        Return the duration of time since the last call to `lap` (or `start`).
        */
        DurationTicks lap(Flag!"enforceNonNegative" enforceNonNegative = Yes.enforceNonNegative)()
        {
            const now = TimestampTicks.now();
            auto duration = now.diff(startLapTime);
            static if (enforceNonNegative)
            {
                if (duration < 0)
                {
                    import std.format : format;
                    assert(0, format("LapTimer.lap has a negative duration (startLapTime %s, now %s, diff %s)",
                        startLapTime, now, duration));
                }
            }
            this.startLapTime = now;
            return duration;
        }
        /**
        Check the current lap time without starting a new lap.
        */
        DurationTicks peek(Flag!"enforceNonNegative" enforceNonNegative = Yes.enforceNonNegative)() const
        {
            const now = TimestampTicks.now();
            auto duration = now.diff(startLapTime);
            static if (enforceNonNegative)
            {
                if (duration < 0)
                {
                    import std.format : format;
                    assert(0, format("LapTimer.lap peek has a negative duration (startLapTime %s, now %s, diff %s)",
                        startLapTime, now, duration));
                }
            }
            return duration;
        }
    }
    /**
    A timer that can be started/stopped and tracks the total duration of time while running.
    */
    struct StopWatchTicks
    {
        private DurationTicks _totalDuration;
        private TimestampTicks _timeStarted;
        private bool _running;

        @property bool running() const { return _running; }
        @property DurationTicks totalDuration() const { return _totalDuration; }

        void start()
        in { assert(!running); } do
        {
            _running = true;
            _timeStarted = TimestampTicks.now();
        }
        DurationTicks stop()
        in { assert(running); } do
        {
            auto duration = TimestampTicks.now().diff(_timeStarted);
            assert(duration >= 0);
            _totalDuration = _totalDuration + duration;
            _running = false;
            return duration;
        }
    }
}

unittest
{
    struct TimePolicy { }
    alias TimestampTicks = TimeTemplate!TimePolicy.TimestampTicks;
}



//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// TODO: MOVE THESE MIXIN TEMPLATES TO A DIFFERENT MODULE
//       maybe something like typecons?
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
mixin template OpUnary(string wrappedFieldName)
{
    mixin(`
        auto opUnary(string op)() inout
        {
            return inout typeof(this)(mixin(op ~ "` ~ wrappedFieldName ~ `"));
        }
`);
}
mixin template OpBinary(string wrappedFieldName, Flag!"includeWrappedType" includeWrappedType)
{
    mixin(`
        auto opBinary(string op)(const typeof(this) rhs) inout
        {
            return inout typeof(this)(mixin("this.` ~ wrappedFieldName ~ ` " ~ op ~ " rhs.` ~ wrappedFieldName ~ `"));
        }
`);
    static if (includeWrappedType) mixin(`
        auto opBinary(string op)(const typeof(` ~ wrappedFieldName ~ `) rhs) inout
        {
            return inout typeof(this)(mixin("this.` ~ wrappedFieldName ~ ` " ~ op ~ " rhs"));
        }
`);
}
mixin template OpCmp(string wrappedFieldName, Flag!"includeWrappedType" includeWrappedType)
{
    mixin(`
        int opCmp(const typeof(this) rhs) const
        {
            return this.` ~ wrappedFieldName ~ `.opCmp(rhs.` ~ wrappedFieldName ~ `);
        }
`);
    static if (includeWrappedType) mixin(`
        int opCmp(const typeof(` ~ wrappedFieldName ~ `) rhs) const
        {
            return this.` ~ wrappedFieldName ~ `.opCmp(rhs);
        }
`);
}
mixin template OpCmpIntegral(string wrappedFieldName, Flag!"includeWrappedType" includeWrappedType)
{
    mixin(`
        int opCmp(const typeof(this) rhs) const
        {
            const result = this.` ~ wrappedFieldName ~ ` - rhs.` ~ wrappedFieldName ~ `;
            if (result < 0) return -1;
            if (result > 0) return 1;
            return 0;
        }
`);
    static if (includeWrappedType) mixin(`
        int opCmp(const typeof(` ~ wrappedFieldName ~ `) rhs) const
        {
            const result = this.` ~ wrappedFieldName ~ ` - rhs;
            if (result < 0) return -1;
            if (result > 0) return 1;
            return 0;
        }
`);
}
+/