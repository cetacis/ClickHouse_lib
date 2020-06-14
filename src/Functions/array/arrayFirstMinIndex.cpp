#include <DataTypes/DataTypesNumber.h>
#include <DataTypes/DataTypesDecimal.h>
#include <Columns/ColumnsNumber.h>
#include <Columns/ColumnDecimal.h>
#include <Functions/array/FunctionArrayMapped.h>
#include <Functions/FunctionFactory.h>


namespace DB
{
/// arrayFirstMinIndex([3, 2, 1]) = 3
namespace ErrorCodes
{
}

struct ArrayFirstMinIndexImpl
{
    static bool useDefaultImplementationForConstants() { return true; }
    static bool needBoolean() { return false; }
    static bool needExpression() { return false; }
    static bool needOneArray() { return false; }

    static DataTypePtr getReturnType(const DataTypePtr &, const DataTypePtr &)
    {
        return std::make_shared<DataTypeUInt32>();
    }

    template <typename T>
    static bool executeType(const ColumnPtr & mapped, const ColumnArray & array, ColumnPtr & res_ptr)
    {
        using ColVecType = std::conditional_t<IsDecimalNumber<T>, ColumnDecimal<T>, ColumnVector<T>>;

        const ColVecType * src_values_column = checkAndGetColumn<ColVecType>(mapped.get());

        if (!src_values_column)
            return false;

        const IColumn::Offsets & src_offsets = array.getOffsets();
        const typename ColVecType::Container & src_values = src_values_column->getData();

        size_t src_offsets_size = src_offsets.size();
        auto res_column = ColumnUInt32::create(src_offsets_size);
        typename ColumnUInt32::Container & res_values = res_column->getData();

        size_t src_pos = 0;

        for (size_t i = 0; i < src_offsets_size; ++i)
        {
            auto m = std::numeric_limits<T>::max();
            auto mi = 0;
            auto src_offset = src_offsets[i];
            if (src_pos < src_offset)
            {
                m = src_values[src_pos];
                mi = src_pos;

                /// For the rest of elements, insert if the element is different from the previous.
                ++src_pos;
                for (; src_pos < src_offset; ++src_pos)
                {
                    if (src_values[src_pos] < m)
                    {
                        m = src_values[src_pos];
                        mi = src_pos;
                    }
                }
            }
            res_values[i] = mi - src_offsets[i - 1] + 1;
        }

        res_ptr = std::move(res_column);
        return true;
    }

    static void executeGeneric(const ColumnPtr & mapped, const ColumnArray & array, ColumnPtr & res_ptr)
    {
        const IColumn::Offsets & src_offsets = array.getOffsets();

        auto res_values_column = mapped->cloneEmpty();
        res_values_column->reserve(mapped->size());

        size_t src_offsets_size = src_offsets.size();
        auto res_offsets_column = ColumnArray::ColumnOffsets::create(src_offsets_size);
        IColumn::Offsets & res_offsets = res_offsets_column->getData();

        size_t res_pos = 0;
        size_t src_pos = 0;

        for (size_t i = 0; i < src_offsets_size; ++i)
        {
            auto src_offset = src_offsets[i];

            /// If array is not empty.
            if (src_pos < src_offset)
            {
                /// Insert first element unconditionally.
                res_values_column->insertFrom(*mapped, src_pos);

                /// For the rest of elements, insert if the element is different from the previous.
                ++src_pos;
                ++res_pos;
                for (; src_pos < src_offset; ++src_pos)
                {
                    if (mapped->compareAt(src_pos - 1, src_pos, *mapped, 1))
                    {
                        res_values_column->insertFrom(*mapped, src_pos);
                        ++res_pos;
                    }
                }
            }
            res_offsets[i] = res_pos;
        }

        res_ptr = ColumnArray::create(std::move(res_values_column), std::move(res_offsets_column));
    }

    static ColumnPtr execute(const ColumnArray & array, ColumnPtr mapped)
    {
        ColumnPtr res;

        if (!(executeType< UInt8 >(mapped, array, res) ||
            executeType< UInt16>(mapped, array, res) ||
            executeType< UInt32>(mapped, array, res) ||
            executeType< UInt64>(mapped, array, res) ||
            executeType< Int8  >(mapped, array, res) ||
            executeType< Int16 >(mapped, array, res) ||
            executeType< Int32 >(mapped, array, res) ||
            executeType< Int64 >(mapped, array, res) ||
            executeType<Float32>(mapped, array, res) ||
            executeType<Float64>(mapped, array, res)) ||
            executeType<Decimal32>(mapped, array, res) ||
            executeType<Decimal64>(mapped, array, res) ||
            executeType<Decimal128>(mapped, array, res))
        {
            // executeGeneric(mapped, array, res);
        }
        return res;
    }
};

struct NameArrayFirstMinIndex { static constexpr auto name = "arrayFirstMinIndex"; };
using FunctionArrayFirstMinIndex = FunctionArrayMapped<ArrayFirstMinIndexImpl, NameArrayFirstMinIndex>;

void registerFunctionArrayFirstMinIndex(FunctionFactory & factory)
{
    factory.registerFunction<FunctionArrayFirstMinIndex>();
}

}

