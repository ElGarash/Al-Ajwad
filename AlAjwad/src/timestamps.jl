### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ b96b428a-e736-11ee-0200-8f1c82cf9893
# ╠═╡ show_logs = false
# ╠═╡ skip_as_script = true
#=╠═╡
begin
	using Pkg
	Pkg.activate("..")
end
  ╠═╡ =#

# ╔═╡ 6639f934-6f3c-4f91-b615-b05e7b88a72f
using JSON, CSV, DataFrames, StringDistances, Printf, IterTools

# ╔═╡ 9658a05d-beb5-4090-a106-7bbf2cfb2166
function load_data()
	root = joinpath("..", "..")
    data_path = joinpath(root, "timestamps")
	sheikhs = sort!(readdir(data_path))[1:end-1]
    file_path = sheikhs[1]
    sheikh = chopsuffix(file_path, ".json")
    
	JSON.parsefile(joinpath(data_path, file_path)), CSV.read(joinpath(root, "ayah_text.csv"), DataFrame), sheikh
end

# ╔═╡ fd680acd-3e93-45b7-9725-e8ad0a638c44
transcription, ayahs_text, sheikh = load_data();

# ╔═╡ b5afda27-fb91-44c6-b3fc-f07fc5dede70
begin
    """
    Get the clear text of a sorah.

    sorah_num: the number of the sorah
    ayah_text: the dataframe of all the ayahs' text
    """
    function get_text_of_sorah(sorah_num, ayahs_text::DataFrame)
        @assert 1 <= sorah_num <= 114
        strip(join(filter(r -> r[:sorah] == sorah_num, ayahs_text)[!, :text], " "))
    end

    """
    sorah_num: the number of the sorah
    transcription: output of whisper
    """
    function get_transcribed_segments(sorah_num)
        @assert 1 <= sorah_num <= 114
        transcription[@sprintf("%03d", sorah_num)]["segments"]
    end

    """
    Group consequtive segments as long as their duration don't exceed 30s
    """
    function accumulate_segments(segments)
        reduce((groups, s) -> begin
                duration = s["end"] - s["start"]
                if isempty(groups) || (groups[end][end]["end"] - groups[end][1]["start"]) + duration >= 30
                    push!(groups, [s])
                else
                    push!(groups[end], s)
                end
                groups
            end, segments, init=Vector{Vector{Dict{String,Any}}}())
    end

    """
    Merge segemnts into a single semgent, the output is the

    ```json
    {
    	"start": the start of the first segment,
    	"end": the end of the last segment,
    	"text": concatenated text of all segments,
    }
    ```
    """
    function merge_segments(segments)
        Dict(
            "start" => segments[1]["start"],
            "end" => segments[end]["end"],
            "text" => strip(replace(join((strip(s["text"]) for s in segments)), r"[\d.-]+" => "")),
        )
    end

    function clean(sorah_num, sheikh, segments, ayahs_text)
        dist = DamerauLevenshtein()
        threshold = 0.1
        df = dirty_hacks!(DataFrame(merge_segments.(accumulate_segments(segments))), sorah_num, sheikh)
        # return df

        sorah_full_text = get_text_of_sorah(sorah_num, ayahs_text)
        words_in_sorah = strip.(split(sorah_full_text, " "))
        if nrow(df) == 1
            df[1, :text] = sorah_full_text
            return df
        end

        sorah_cursor = 1
        segment_cursor = 1


        while sorah_cursor < length(words_in_sorah)
            if segment_cursor > nrow(df)
                println("Truncated!")
                break
            end
            segment_text = df[segment_cursor, :text]
            words_in_segment = split(segment_text, " ")

            curr_range = sorah_cursor + length(words_in_segment) - 1
            sorah_idx = curr_range < length(words_in_sorah) ? (sorah_cursor:curr_range) : (sorah_cursor:lastindex(words_in_sorah))

            coresponding_words_in_sorah = join(words_in_sorah[sorah_idx], " ")

            d = dist(coresponding_words_in_sorah, segment_text)
            normalized_distnace = d / length(segment_text)

            # println(normalized_distnace)
            # println(sorah_cursor)
            if 0 < normalized_distnace <= threshold
                # if segment_cursor == 60
                # 	println("up")
                # end
                # println(normalized_distnace)
                # println(segment_text)
                # println(coresponding_words_in_sorah)
                df[segment_cursor, :text] = coresponding_words_in_sorah
            end

            if normalized_distnace > threshold && !dirty_skip(sorah_num, sheikh, segment_cursor)
                # if segment_cursor == 60
                # 	println("down")
                # end
                best_effort = join(argmin(
                        ws -> dist(join(ws, " "), segment_text),
                        [words_in_sorah[sorah_cursor:end][1:i] for i in 1:length(words_in_sorah[sorah_cursor:end])],
                    ), " ")
                # println("segment_texts: ", segment_text)
                # println("best_effort: ", best_effort)
                # println("coresponding_words_in_sorah: ", coresponding_words_in_sorah)
                # println(repeat("==", 10))
                df[segment_cursor, :text] = best_effort
            end

            sorah_cursor += length(split(df[segment_cursor, :text], " "))
            segment_cursor += 1
            # println(normalized_distnace)
            # println(sorah_cursor)
            # println(length(words_in_sorah))
        end
        return df
    end

    function dirty_hacks!(df::DataFrame, sorah_num, sheikh)
        if sheikh == "AbdulBaset AbdulSamad_Mujawwad"
            if sorah_num == 97
                pop!(df)
            end

            if sorah_num == 58
                pop!(df)
            end
        end

        return df
    end

    """
    Don't try to process a semgent
    """
    function dirty_skip(sorah_num, sheikh, segment_cursor)
        skip = false
        if sheikh == "AbdulBaset AbdulSamad_Mujawwad"
            skip = sorah_num == 65 && segment_cursor == 36
        end
        return skip
    end

    function assert_zero_distance(s1, s2, sorah_num, sheikh)
        d = DamerauLevenshtein()(s1, s2)
        if sorah_num == 65
            return d == 32
        end
        return d == 0
    end
end

# ╔═╡ b78ea739-9230-4d11-89fb-5486fd4742e5
begin
    sorah_num = 114
    segments = get_transcribed_segments(sorah_num)
    df = clean(sorah_num, sheikh, segments, ayahs_text)
end

# ╔═╡ 4cdd93ae-bf07-4159-8dc3-117498e187a9
begin
    s1 = join(df[!, :text], " ")
    s2 = get_text_of_sorah(sorah_num, ayahs_text)
    assert_zero_distance(s1, s2, sorah_num, sheikh)
end

# ╔═╡ 4551fd24-d4ee-4195-abf2-1bd595b33fdf
println(s2)

# ╔═╡ 630ecad0-a2a1-4cee-90de-8c22372f78cc
md"
## Problematic transcriptions

1. `66`: translation of the sorah
2. `59`: timestamps are shifted starting from `13:05`
3. `57`: timestamps are shifted starting from `3:32`, and text is wrong too
4. `53`: timestamps are shifted starting from `5:33`
5. `47`: timestamps are shifted starting from `15:14`
6. `45`: timestamps 
7. `43`: timestamps
8. `42`: timestamps
"

# ╔═╡ 214dce2f-3348-4816-af9d-6579e7039631
begin
    function concat_segments(segments)
        join([d["text"] for d in segments], " ")
    end

    all_segments = get_transcribed_segments.(1:114)
    all_segments_concatenated = concat_segments.(all_segments)
    filter(Bool, [occursin("نانسي", s) for s in all_segments_concatenated])
end

# ╔═╡ Cell order:
# ╠═b96b428a-e736-11ee-0200-8f1c82cf9893
# ╠═6639f934-6f3c-4f91-b615-b05e7b88a72f
# ╠═9658a05d-beb5-4090-a106-7bbf2cfb2166
# ╠═fd680acd-3e93-45b7-9725-e8ad0a638c44
# ╠═b5afda27-fb91-44c6-b3fc-f07fc5dede70
# ╠═b78ea739-9230-4d11-89fb-5486fd4742e5
# ╠═4cdd93ae-bf07-4159-8dc3-117498e187a9
# ╠═4551fd24-d4ee-4195-abf2-1bd595b33fdf
# ╠═630ecad0-a2a1-4cee-90de-8c22372f78cc
# ╠═214dce2f-3348-4816-af9d-6579e7039631
