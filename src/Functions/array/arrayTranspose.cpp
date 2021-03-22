#include <Columns/ColumnArray.h>
#include <DataTypes/DataTypeArray.h>
#include <Functions/FunctionFactory.h>
#include <Functions/FunctionHelpers.h>
#include <Functions/IFunction.h>

namespace DB
{
namespace ErrorCodes
{
    extern const int ILLEGAL_COLUMN;
}

class FunctionArrayTranspose : public IFunction
{
public:
    static constexpr auto name = "arrayTranspose";

    static FunctionPtr create(ContextPtr) { return std::make_shared<FunctionArrayTranspose>(); }

    bool isSuitableForShortCircuitArgumentsExecution(const DataTypesWithConstInfo & /*arguments*/) const override { return false; }

    size_t getNumberOfArguments() const override { return 1; }

    bool useDefaultImplementationForConstants() const override { return true; }

    DataTypePtr getReturnTypeImpl(const DataTypes & arguments) const override
    {
        if (!isArray(arguments[0]))
            throw Exception(
                ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT,
                "Illegal type {} of argument of function {}, expected Array of Array",
                arguments[0]->getName(),
                getName());

        DataTypePtr nested_type = checkAndGetDataType<DataTypeArray>(arguments[0].get())->getNestedType();

        if (!isArray(nested_type))
            throw Exception(
                ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT,
                "Illegal type {} of argument of function {}, expected Array of Array",
                arguments[0]->getName(),
                getName());

        nested_type = checkAndGetDataType<DataTypeArray>(nested_type.get())->getNestedType();

        if (!isNativeNumber(*nested_type))
            throw Exception(
                ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT,
                "Illegal type {} of argument of function {}, expected Array of Array of Native Number",
                arguments[0]->getName(),
                getName());

        return arguments[0];
    }

    ColumnPtr executeImpl(const ColumnsWithTypeAndName & arguments, const DataTypePtr &, size_t input_rows_count) const override
    {
        const ColumnArray * src_col = checkAndGetColumn<ColumnArray>(arguments[0].column.get());

        if (!src_col)
            throw Exception(ErrorCodes::ILLEGAL_COLUMN, "Illegal column {} in argument of function 'arrayTranspose'", arguments[0].name);

        auto result_col = src_col->cloneEmpty();

        if (input_rows_count)
        {
            if (executeType<UInt8>(src_col, result_col) || executeType<UInt16>(src_col, result_col)
                || executeType<UInt32>(src_col, result_col) || executeType<UInt64>(src_col, result_col)
                || executeType<Int8>(src_col, result_col) || executeType<Int16>(src_col, result_col)
                || executeType<Int32>(src_col, result_col) || executeType<Int64>(src_col, result_col)
                || executeType<Float32>(src_col, result_col) || executeType<Float64>(src_col, result_col))
                ;
            else
                throw Exception(ErrorCodes::ILLEGAL_COLUMN, "Unexpected column for arrayTranspose: {}", src_col->getName());
        }
        return result_col;
    }

    template <typename ColumnType>
    bool executeType(const ColumnArray * src_col, MutableColumnPtr & result_col) const
    {
        ColumnArray * res_col = typeid_cast<ColumnArray *>(&*result_col);
        const IColumn::Offsets & offsets = src_col->getOffsets();
        IColumn::Offsets & result_offsets = res_col->getOffsets();
        const auto & src_data = typeid_cast<const ColumnArray &>(src_col->getData());
        auto & result_data = typeid_cast<ColumnArray &>(res_col->getData());

        const IColumn::Offsets & sub_offsets = src_data.getOffsets();
        IColumn::Offsets & sub_result_offsets = result_data.getOffsets();
        auto sub_src_data = checkAndGetColumn<ColumnVector<ColumnType>>(src_data.getData());
        if (!sub_src_data)
            return false;
        auto & sub_src = sub_src_data->getData();
        auto & sub_result = typeid_cast<ColumnVector<ColumnType> &>(result_data.getData()).getData();

        size_t rows = offsets.size();
        result_offsets.resize(rows);

        size_t col_num = 0;
        for (size_t row = 0ul; row < rows; ++row)
        {
            size_t col_size = sub_offsets[offsets[row - 1]] - sub_offsets[offsets[row - 1] - 1];
            for (auto col = offsets[row - 1] + 1; col < offsets[row]; ++col)
            {
                if (sub_offsets[col] - sub_offsets[col - 1] != col_size)
                    throw Exception(
                        ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT, "arrayTranspose only works for Matrix, received unaligned Array of Array");
            }
            col_num += col_size;
            result_offsets[row] = result_offsets[row - 1] + col_size;
        }
        sub_result_offsets.resize(col_num);
        sub_result.resize(sub_src.size());
        size_t mat_size = 0ul;
        for (auto row = 0ul; row < rows; ++row)
        {
            size_t row_size = offsets[row] - offsets[row - 1];
            size_t col_size = sub_offsets[offsets[row - 1]] - sub_offsets[offsets[row - 1] - 1];
            for (size_t col = result_offsets[row - 1]; col < result_offsets[row]; ++col)
                sub_result_offsets[col] = sub_result_offsets[col - 1] + row_size;
            for (auto i = 0ul; i < row_size; ++i)
                for (size_t j = 0ul; j < col_size; ++j)
                    sub_result[mat_size + j * row_size + i] = sub_src[mat_size + i * col_size + j];
            mat_size += row_size * col_size;
        }
        return true;
    }

private:
    String getName() const override { return name; }
};

REGISTER_FUNCTION(ArrayTranspose)
{
    factory.registerFunction<FunctionArrayTranspose>();
    factory.registerAlias("atp", "arrayTranspose", FunctionFactory::CaseInsensitive);
}

}
