#include <Columns/ColumnString.h>
#include <DataTypes/DataTypeString.h>
#include <Functions/FunctionFactory.h>
#include <Functions/IFunction.h>
#include <Parsers/ParserQuery.h>
#include <Parsers/parseQuery.h>

namespace DB
{

namespace ErrorCodes
{
    extern const int ILLEGAL_TYPE_OF_ARGUMENT;
    extern const int LOGICAL_ERROR;
}

class FunctionQueryToJSON : public IFunction
{
public:
    static constexpr auto name = "queryToJSON";

    static FunctionPtr create(const Context &)
    {
        return std::make_shared<FunctionQueryToJSON>();
    }

    String getName() const override
    {
        return name;
    }

    size_t getNumberOfArguments() const override
    {
        return 1;
    }

    bool useDefaultImplementationForConstants() const override
    {
        return true;
    }

    DataTypePtr getReturnTypeImpl(const DataTypes & arguments) const override
    {
        if (!isStringOrFixedString(arguments[0]))
            throw Exception("The only argument for function " + getName() + " must be String", ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT);
        return std::make_shared<DataTypeString>();
    }

    void executeImpl(Block & block, const ColumnNumbers & arguments, size_t result, size_t input_rows_count) override
    {
        const IColumn * input = block.getByPosition(arguments[0]).column.get();

        auto col_res = ColumnString::create();

        Field str;
        for (auto i = 0ul; i < input_rows_count; ++i)
        {
            input->get(i, str);
            if (str.getType() == Field::Types::String)
            {
                auto & query = str.get<String>();
                ParserQuery parser(query.data() + query.size(), 0);
                ASTPtr ast = parseQuery(parser, query.data(), query.data() + query.size(), "", 0, 0);
                std::stringstream ostr;
                ast->dumpJSON(ostr);
                col_res->insert(ostr.str());
            }
            else
                throw Exception("Input column should contain string", ErrorCodes::LOGICAL_ERROR);
        }

        block.getByPosition(result).column = std::move(col_res);
    }
};

void registerFunctionQueryToJSON(FunctionFactory & factory)
{
    factory.registerFunction<FunctionQueryToJSON>();
}

}
