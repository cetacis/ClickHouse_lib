#include <DataTypes/DataTypeString.h>
#include <DataTypes/DataTypeFixedString.h>
#include <DataTypes/DataTypeArray.h>
#include <Columns/ColumnString.h>
#include <Columns/ColumnFixedString.h>
#include <Columns/ColumnArray.h>
#include <Columns/ColumnNullable.h>
#include <Columns/ColumnsNumber.h>
#include <Interpreters/Context_fwd.h>
#include <Interpreters/ITokenExtractor.h>
#include <Functions/IFunction.h>
#include <Functions/FunctionHelpers.h>
#include <Functions/FunctionFactory.h>


namespace DB
{

namespace ErrorCodes
{
    extern const int BAD_ARGUMENTS;
}

enum TokenExtractorStrategy
{
    ngrams,
    tokens
};

template <TokenExtractorStrategy strategy>
class FunctionTokenExtractor : public IFunction
{
public:

    static constexpr auto name = strategy == ngrams ? "ngrams" : "tokens";

    static FunctionPtr create(ContextPtr)
    {
        return std::make_shared<FunctionTokenExtractor>();
    }

    String getName() const override { return name; }

    size_t getNumberOfArguments() const override { return strategy == ngrams ? 2 : 1; }
    bool isVariadic() const override { return false; }
    ColumnNumbers getArgumentsThatAreAlwaysConstant() const override { return strategy == ngrams ? ColumnNumbers{1} : ColumnNumbers{}; }

    bool useDefaultImplementationForNulls() const override { return false; }
    bool useDefaultImplementationForConstants() const override { return true; }
    bool useDefaultImplementationForLowCardinalityColumns() const override { return true; }
    bool isSuitableForShortCircuitArgumentsExecution(const DataTypesWithConstInfo & /*arguments*/) const override { return true; }

    DataTypePtr getReturnTypeImpl(const ColumnsWithTypeAndName & arguments) const override
    {
        auto ngram_input_argument_type = WhichDataType(removeNullable(arguments[0].type));
        if (!ngram_input_argument_type.isStringOrFixedString())
            throw Exception(ErrorCodes::BAD_ARGUMENTS,
                "Function {} first argument type should be String or FixedString. Actual {}",
                getName(),
                arguments[0].type->getName());

        if constexpr (strategy == ngrams)
        {
            const auto & column_with_type = arguments[1];
            const auto & ngram_argument_column = arguments[1].column;
            auto ngram_argument_type = WhichDataType(column_with_type.type);

            if (!ngram_argument_type.isNativeUInt() || !ngram_argument_column || !isColumnConst(*ngram_argument_column))
                throw Exception(ErrorCodes::BAD_ARGUMENTS,
                    "Function {} second argument type should be constant UInt. Actual {}",
                    getName(),
                    arguments[1].type->getName());
        }

        return std::make_shared<DataTypeArray>(std::make_shared<DataTypeString>());
    }

    ColumnPtr executeImpl(const ColumnsWithTypeAndName & arguments, const DataTypePtr &, size_t) const override
    {
        auto column_offsets = ColumnArray::ColumnOffsets::create();
        auto input_column = arguments[0].column;
        const ColumnUInt8::Container * null_map = nullptr;

        if (const auto * nullable = checkAndGetColumn<ColumnNullable>(input_column.get()))
        {
            null_map = &nullable->getNullMapData();
            input_column = nullable->getNestedColumnPtr();
        }

        if constexpr (strategy == TokenExtractorStrategy::ngrams)
        {
            Field ngram_argument_value;
            arguments[1].column->get(0, ngram_argument_value);
            auto ngram_value = ngram_argument_value.safeGet<UInt64>();

            NgramTokenExtractor extractor(ngram_value);

            auto result_column_string = ColumnString::create();


            if (const auto * column_string = checkAndGetColumn<ColumnString>(input_column.get()))
                executeImpl(extractor, *column_string, *result_column_string, *column_offsets, null_map);
            else if (const auto * column_fixed_string = checkAndGetColumn<ColumnFixedString>(input_column.get()))
                executeImpl(extractor, *column_fixed_string, *result_column_string, *column_offsets, null_map);

            return ColumnArray::create(std::move(result_column_string), std::move(column_offsets));
        }
        else
        {
            SplitTokenExtractor extractor;

            auto result_column_string = ColumnString::create();

            if (const auto * column_string = checkAndGetColumn<ColumnString>(input_column.get()))
                executeImpl(extractor, *column_string, *result_column_string, *column_offsets, null_map);
            else if (const auto * column_fixed_string = checkAndGetColumn<ColumnFixedString>(input_column.get()))
                executeImpl(extractor, *column_fixed_string, *result_column_string, *column_offsets, null_map);

            return ColumnArray::create(std::move(result_column_string), std::move(column_offsets));
        }
    }

private:

    template <typename ExtractorType, typename StringColumnType, typename ResultStringColumnType>
    void executeImpl(
        const ExtractorType & extractor,
        StringColumnType & input_data_column,
        ResultStringColumnType & result_data_column,
        ColumnArray::ColumnOffsets & offsets_column,
        const ColumnUInt8::Container * null_map) const
    {
        size_t current_tokens_size = 0;
        auto & offsets_data = offsets_column.getData();

        size_t column_size = input_data_column.size();
        offsets_data.resize(column_size);

        auto work = [&]<bool has_null>()
        {
            for (size_t i = 0; i < column_size; ++i)
            {
                if constexpr (has_null)
                {
                    if ((*null_map)[i])
                    {
                        offsets_data[i] = current_tokens_size;
                        continue;
                    }
                }
                auto data = input_data_column.getDataAt(i);

                size_t cur = 0;
                size_t token_start = 0;
                size_t token_length = 0;

                while (cur < data.size && extractor.nextInStringPadded(data.data, data.size, &cur, &token_start, &token_length))
                {
                    result_data_column.insertData(data.data + token_start, token_length);
                    ++current_tokens_size;
                }

                offsets_data[i] = current_tokens_size;
            }
        };

        if (null_map)
            work.template operator()<true>();
        else
            work.template operator()<false>();
    }
};

REGISTER_FUNCTION(StringTokenExtractor)
{
    factory.registerFunction<FunctionTokenExtractor<TokenExtractorStrategy::ngrams>>();
    factory.registerFunction<FunctionTokenExtractor<TokenExtractorStrategy::tokens>>();
}

}
