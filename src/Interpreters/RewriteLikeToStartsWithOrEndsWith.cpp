#include <Interpreters/RewriteLikeToStartsWithOrEndsWith.h>
#include <Parsers/ASTFunction.h>
#include <Parsers/ASTLiteral.h>
#include <Poco/String.h>

namespace DB
{

namespace
{

String extractPrefixFromLikePattern(std::string_view like_pattern)
{
    String fixed_prefix;
    fixed_prefix.reserve(like_pattern.size());

    const char * pos = like_pattern.data();
    const char * end = pos + like_pattern.size();
    while (pos < end)
    {
        switch (*pos)
        {
            case '%':
                if (std::all_of(pos, end, [](auto c) { return c == '%'; }))
                    return fixed_prefix;
                else
                    return "";
            case '_':
                return "";
            case '\\':
                ++pos;
                if (pos == end)
                    break;
                [[fallthrough]];
            default:
                fixed_prefix += *pos;
        }

        ++pos;
    }

    return fixed_prefix;
}

String extractSuffixFromLikePattern(std::string_view like_pattern)
{
    String fixed_suffix;
    fixed_suffix.reserve(like_pattern.size());

    const char * pos = like_pattern.data();
    const char * end = pos + like_pattern.size();
    while (pos < end)
    {
        switch (*pos)
        {
            case '%':
                if (!fixed_suffix.empty())
                    return "";
                break;
            case '_':
                return "";
            case '\\':
                ++pos;
                if (pos == end)
                    break;
                [[fallthrough]];
            default:
                fixed_suffix += *pos;
        }

        ++pos;
    }

    return fixed_suffix;
}

}

void RewriteLikeToStartsWithOrEndsWithData::visit(ASTFunction & function, ASTPtr & /* ast */) const
{
    if (function.name != "like" && function.name != "ilike")
        return;

    bool case_sensitive = function.name == "like";

    auto & arguments = function.arguments->children;
    if (arguments.size() != 2)
        return;

    const auto * literal = arguments[1]->as<ASTLiteral>();
    if (!literal || (literal->value.getType() != Field::Types::String))
        return;

    String pattern = literal->value.safeGet<String>();

    auto prefix = extractPrefixFromLikePattern(pattern);
    if (!prefix.empty())
    {
        function.name = "startsWith";
        if (!case_sensitive)
        {
            arguments[0] = makeASTFunction("lower", arguments[0]);
            arguments[1] = std::make_shared<ASTLiteral>(Poco::toLower(prefix));
        }
        else
        {
            arguments[1] = std::make_shared<ASTLiteral>(prefix);
        }

        return;
    }

    auto suffix = extractSuffixFromLikePattern(pattern);
    if (!suffix.empty())
    {
        function.name = "endsWith";
        if (!case_sensitive)
        {
            arguments[0] = makeASTFunction("lower", arguments[0]);
            arguments[1] = std::make_shared<ASTLiteral>(Poco::toLower(suffix));
        }
        else
        {
            arguments[1] = std::make_shared<ASTLiteral>(suffix);
        }

        return;
    }
}

}
