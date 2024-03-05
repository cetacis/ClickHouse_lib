#pragma once

#include <base/types.h>
#include <Common/BitHelpers.h>
#include <Common/formatReadable.h>
#include <Common/logger_useful.h>

struct PackedLongValues
{
    struct Page
    {
        Page(const std::vector<UInt64> & vals, size_t bits_per_val_, size_t num_longs)
            : bits_per_val(bits_per_val_), min_val(vals.front()), longs(std::make_unique<UInt64[]>(num_longs))
        {
            size_t pos = 0;
            size_t offset = 0;

            for (auto v : vals)
            {
                auto val = v - min_val;
                if (offset == 0)
                {
                    longs[pos] = val;
                }
                else
                {
                    longs[pos] |= val << offset;
                    if (offset + bits_per_val > 64)
                        longs[pos + 1] = val >> (64 - offset);
                }

                offset += bits_per_val;
                if (offset >= 64)
                {
                    ++pos;
                    offset -= 64;
                }
            }
        }

        UInt64 operator[](size_t i) const
        {
            size_t bits = i * bits_per_val;
            size_t pos = bits / 64;
            size_t offset = bits % 64;
            UInt64 value = longs[pos] >> offset;
            if (offset + bits_per_val > 64)
                value |= longs[pos + 1] << (64 - offset);

            return min_val + (value & maskLowBits<UInt64>(bits_per_val));
        }

        size_t bits_per_val;
        size_t min_val;
        std::unique_ptr<UInt64[]> longs;
    };

    void insert(UInt64 val)
    {
        if (longs.size() >= page_size)
            flush();

        longs.push_back(val);
    }

    void flush()
    {
        if (longs.empty())
            return;

        size_t bits_per_val = sizeof(size_t) * 8 - getLeadingZeroBits(longs.back() - longs.front());
        size_t num_longs = ((longs.size() * bits_per_val) + 63) / 64 + 1;
        pages.emplace_back(longs, bits_per_val, num_longs);
        total_memory += num_longs * 8 + 24;
        longs.clear();
    }

    UInt64 operator[](size_t i) const { return pages[i >> page_size_degree][i & page_mask]; }

    static constexpr UInt8 page_size_degree = 10;
    static constexpr size_t page_size = 1 << page_size_degree;
    static constexpr size_t page_mask = page_size - 1;
    std::vector<Page> pages;
    std::vector<UInt64> longs;
    size_t total_memory = 0;
};

struct PartsOffsets
{
    PartsOffsets() = default;

    explicit PartsOffsets(std::vector<UInt64> starting_offsets_, size_t total_rows_)
        : starting_offsets(std::move(starting_offsets_))
        , total_rows(total_rows_)
        , num_parts(starting_offsets.size())
        , offset_maps(num_parts)
    {
    }

    void insert(const UInt64 * begin, const UInt64 * end)
    {
        for (const UInt64 * it = begin; it != end; ++it)
        {
            size_t pos = 0;
            while (pos < num_parts - 1)
            {
                if (starting_offsets[pos + 1] > *it)
                    break;

                ++pos;
            }

            chassert(pos < offset_maps.size());
            offset_maps[pos].insert(num_rows++);
        }
    }

    UInt64 operator[](UInt64 offset) const
    {
        size_t pos = 0;
        while (pos < num_parts - 1)
        {
            if (starting_offsets[pos + 1] > offset)
                break;

            ++pos;
        }

        chassert(pos < offset_maps.size());
        UInt64 new_offset = offset - starting_offsets[pos];
        return offset_maps[pos][new_offset];
    }

    void flush()
    {
        if (num_rows == 0)
            return;

        if (num_rows > 0)
            chassert(total_rows == num_rows);

        size_t total_memory = 0;
        for (auto & map : offset_maps)
        {
            map.flush();
            {
                std::vector<UInt64> longs;
                std::swap(map.longs, longs);
            }

            total_memory += map.total_memory;
        }

        LOG_DEBUG(log, "rows = {}, memory = {}", total_rows, formatReadableSizeWithBinarySuffix(total_memory));
    }

    bool empty() const { return num_rows == 0; }

    size_t size() const { return num_rows; }

    std::vector<UInt64> starting_offsets;
    size_t total_rows = 0;
    size_t num_parts = 0;
    std::vector<PackedLongValues> offset_maps;
    size_t num_rows = 0;
    Poco::Logger * log = &Poco::Logger::get("PartsOffsets");
};
