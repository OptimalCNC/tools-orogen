#define OROCOS_TARGET gnulinux

#include <rtt/internal/DataSources.hpp>
#include <rtt/os/main.h>
#include <rtt/typekit/RealTimeTypekit.hpp>
#include <rtt/types/TypekitPlugin.hpp>
#include <rtt/types/Types.hpp>

#include "enum_stream/typekit/Plugin.hpp"
#include "enum_stream/typekit/Types.hpp"

#include <iostream>
#include <sstream>

int ORO_main(int, char**)
{
    RTT::types::TypekitRepository::Import(
        new RTT::types::RealTimeTypekitPlugin);
    RTT::types::TypekitRepository::Import(
        new orogen_typekits::enum_streamTypekitPlugin);

    RTT::types::TypeInfo* plain_ti =
        RTT::types::Types()->type("/enum_stream/PlainState");

    if (!plain_ti) {
        std::cerr << "missing type info for /enum_stream/PlainState\n";
        return 1;
    }

    RTT::internal::ValueDataSource<enum_stream::PlainState>::shared_ptr plain_value =
        new RTT::internal::ValueDataSource<enum_stream::PlainState>(
            enum_stream::PLAIN_RUNNING);

    std::stringstream plain_out;
    plain_ti->write(plain_out, plain_value);

    if (plain_out.str() != "PLAIN_RUNNING") {
        std::cerr << "expected PLAIN_RUNNING, got " << plain_out.str() << "\n";
        return 1;
    }

    RTT::types::TypeInfo* scoped_ti =
        RTT::types::Types()->type("/enum_stream/ScopedState");

    if (!scoped_ti) {
        std::cerr << "missing type info for /enum_stream/ScopedState\n";
        return 1;
    }

    RTT::internal::ValueDataSource<enum_stream::ScopedState>::shared_ptr scoped_value =
        new RTT::internal::ValueDataSource<enum_stream::ScopedState>(
            enum_stream::ScopedState::SCOPED_RUNNING);

    std::stringstream scoped_out;
    scoped_ti->write(scoped_out, scoped_value);

    if (scoped_out.str() != "SCOPED_RUNNING") {
        std::cerr << "expected SCOPED_RUNNING, got " << scoped_out.str() << "\n";
        return 1;
    }

    return 0;
}
