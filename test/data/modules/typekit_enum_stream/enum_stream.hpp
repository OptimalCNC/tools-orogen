#ifndef TYPEKIT_ENUM_STREAM_HPP
#define TYPEKIT_ENUM_STREAM_HPP

namespace enum_stream {
    enum PlainState {
        PLAIN_IDLE = 0,
        PLAIN_RUNNING = 2
    };

    enum class ScopedState {
        SCOPED_IDLE = 0,
        SCOPED_RUNNING = 2
    };
}

#endif
