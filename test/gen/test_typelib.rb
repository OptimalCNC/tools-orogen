# frozen_string_literal: true

require "orogen/gen/test"

describe Typelib do
    attr_reader :registry

    before do
        @registry = Typelib::CXXRegistry.new
    end

    describe Typelib::NumericType do
        describe "#cxx_name" do
            it "returns the equivalent standard fixed-width type" do
                expected_names = {
                    "/int8_t" => "std::int8_t",
                    "/uint8_t" => "std::uint8_t",
                    "/int16_t" => "std::int16_t",
                    "/uint16_t" => "std::uint16_t",
                    "/int32_t" => "std::int32_t",
                    "/uint32_t" => "std::uint32_t",
                    "/int64_t" => "std::int64_t",
                    "/uint64_t" => "std::uint64_t"
                }

                expected_names.each do |type_name, cxx_name|
                    assert_equal cxx_name, registry.get(type_name).cxx_name
                end
            end
        end
    end

    describe Typelib::Registry do
        describe ".rtt_typename" do
            it "maps Typelib built-ins to canonical RTT type names" do
                expected_names = {
                    "/bool" => "Bool",
                    "/int8_t" => "Int8",
                    "/uint8_t" => "UInt8",
                    "/int16_t" => "Int16",
                    "/uint16_t" => "UInt16",
                    "/int32_t" => "Int32",
                    "/uint32_t" => "UInt32",
                    "/int64_t" => "Int64",
                    "/uint64_t" => "UInt64",
                    "/float" => "Float32",
                    "/double" => "Float64",
                    "/std/string" => "String",
                    "/nil" => "Void"
                }

                expected_names.each do |type_name, rtt_name|
                    type = registry.get(type_name)
                    assert_equal rtt_name, Typelib::Registry.rtt_typename(type)
                    assert Typelib::Registry.base_rtt_type?(type)
                end
            end

            it "maps a distinct C char type to Char" do
                char_registry = Typelib::Registry.new
                char_type = char_registry.create_numeric "/char", 1, :sint

                assert_equal "Char", Typelib::Registry.rtt_typename(char_type)
                assert Typelib::Registry.base_rtt_type?(char_type)
            end

            it "maps C++ integer aliases to their canonical width" do
                assert_equal "Int16",
                             Typelib::Registry.rtt_typename(registry.get("/short"))
                assert_equal "UInt16",
                             Typelib::Registry.rtt_typename(registry.get("/unsigned short"))
                assert_equal "Int32",
                             Typelib::Registry.rtt_typename(registry.get("/int"))
                assert_equal "UInt32",
                             Typelib::Registry.rtt_typename(registry.get("/unsigned int"))
            end

            it "rejects numeric types that RTT does not provide" do
                unknown = Typelib::Registry.new.create_numeric "/int24_t", 3, :sint

                assert_raises(ArgumentError) do
                    Typelib::Registry.rtt_typename(unknown)
                end
            end
        end
    end

    describe OroGen::Loaders::RTT do
        it "exports the complete RTT-owned interface without an external std typekit" do
            project = OroGen::Gen::RTT_CPP::Project.new
            interface_types = %w[
                /bool /char /int8_t /uint8_t /int16_t /uint16_t
                /int32_t /uint32_t /int64_t /uint64_t /float /double
                /std/string /std/vector</double> /array /nil /void
            ]

            interface_types.each do |type_name|
                assert project.registry.include?(type_name), type_name
                assert project.exported_type?(type_name), type_name
            end
        end
    end
end
