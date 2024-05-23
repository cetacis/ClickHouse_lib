#pragma once

#include <Interpreters/InDepthNodeVisitor.h>

namespace DB
{

class ASTFunction;

class RewriteLikeToStartsWithOrEndsWithData
{
public:
    using TypeToVisit = ASTFunction;
    void visit(ASTFunction & function, ASTPtr & ast) const;
};

using RewriteLikeToStartsWithOrEndsWithMatcher = OneTypeMatcher<RewriteLikeToStartsWithOrEndsWithData>;
using RewriteLikeToStartsWithOrEndsWithVisitor = InDepthNodeVisitor<RewriteLikeToStartsWithOrEndsWithMatcher, true>;

}
