# frozen_string_literal: true

module Typelib
    class Type
        def self.normalize_typename(name)
            "/" + Typelib.split_typename(name).map do |part|
                normalize_typename_part(part)
            end.join("/")
        end

        TYPENAME_ARRAY_MATCH = /(.*)(\[\d+\]+)$/.freeze

        def self.normalize_typename_part(name)
            # Remove all trailing array modifiers first
            if (m = TYPENAME_ARRAY_MATCH.match(name))
                name = m[1]
                array_modifiers = m[2]
            end

            name, template_arguments = Typelib::GCCXMLLoader.parse_template(name)
            template_arguments.map! do |arg|
                if arg !~ /^\d+$/ && arg[0, 1] != "/"
                    "/#{arg}"
                else
                    arg
                end
            end

            if !template_arguments.empty?
                "#{name}<#{template_arguments.join(',')}>#{array_modifiers}"
            else
                "#{name}#{array_modifiers}"
            end
        end

        def self.normalize_cxxname(name)
            if name =~ /::/
                raise InternalError,
                      "normalize_cxxname called with a C++ type name (#{name})"
            end

            if name =~ /(.*)((?:\[\d+\])+)$/
                name = ::Regexp.last_match(1)
                suffix = ::Regexp.last_match(2)
            else
                suffix = ""
            end

            converted = Typelib.split_typename(name).map do |p|
                normalize_cxxname_part(p)
            end
            if converted.size == 1
                "#{converted.first}#{suffix}"
            else
                "::" + converted.join("::") + suffix
            end
        end

        def self.normalize_cxxname_part(name)
            name, template_arguments = Typelib::GCCXMLLoader.parse_template(name)

            name = name.gsub("/", "::")
            name = ::Regexp.last_match(1) if name =~ /^::(.*)/

            if !template_arguments.empty?
                template_arguments.map! do |arg|
                    if arg !~ /^\d+$/
                        normalize_cxxname(arg)
                    else
                        arg
                    end
                end

                "#{name}< #{template_arguments.join(', ')} >"
            else
                name
            end
        end

        def self.cxx_name
            normalize_cxxname(name)
        end

        def self.cxx_basename
            normalize_cxxname(basename)
        end

        def self.cxx_namespace
            namespace("::")
        end

        def self.contains_opaques?
            return @contains_opaques unless @contains_opaques.nil?

            @contains_opaques = contains?(Typelib::OpaqueType)
        end
    end

    class NumericType
        def self.cxx_name
            if integer?
                if name == "/bool"
                    "bool"
                elsif name == "/char"
                    "char"
                elsif name == "/unsigned char"
                    "unsigned char"
                else
                    "std::#{'u' if unsigned?}int#{size * 8}_t"
                end
            else
                basename
            end
        end
    end

    class ContainerType
        def self.cxx_name
            if name =~ /</
                normalize_cxxname(container_kind) + "< " + deference.cxx_name + " >"
            else
                normalize_cxxname(container_kind)
            end
        end
    end

    class Registry
        RTT_BUILTIN_TYPE_NAMES = {
            "/bool" => "Bool",
            "/char" => "Char",
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
        }.freeze

        # Returns true if +type+ is handled by the typekit that is included in
        # the RTT itself, and false otherwise.
        #
        # This is used in property bags and in the interface definition, as --
        # among the simple types -- only these can be used directly in
        # interfaces.
        def self.base_rtt_type?(type)
            RTT_BUILTIN_TYPE_NAMES.key?(type.name)
        end

        # Returns the typename used by RTT to register the given type
        def self.rtt_typename(type)
            if (rtt_name = RTT_BUILTIN_TYPE_NAMES[type.name])
                rtt_name
            elsif !(type <= Typelib::NumericType)
                return type.name
            else
                raise ArgumentError,
                      "#{type.name} is (probably) not registered on the RTT type system"
            end
        end
    end
end
