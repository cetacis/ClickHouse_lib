#include <Functions/tuple.h>

namespace DB
{

REGISTER_FUNCTION(Tuple)
{
    factory.registerFunction<FunctionTuple>(FunctionDocumentation{
        .description = R"(
Returns a tuple by grouping input arguments.

For columns C1, C2, … with the types T1, T2, …, it returns a Tuple(C1 T1, C2 T2, …) type tuple containing these columns. There is no cost to execute the function.
If there are duplicate column names, subsequent names will be suffixed with `_N` starting from zero. For example, `tuple(C1, C1)` will return a Tuple(C1 T1, C1_0 T1).
Tuples are normally used as intermediate values for an argument of IN operators, or for creating a list of formal parameters of lambda functions. Tuples can’t be written to a table.

The function implements the operator `(x, y, …)`.
)",
        .examples{{"typical", "SELECT tuple(1, 2)", "(1,2)"}},
        .categories{"Miscellaneous"}});
}

}
