export start_end, slide, nearest_start_end
const μs = 1.0e-6
const sμ = 1000000.0
"""

  start_end(C::SeisChannel)

Return start and endtimes of SeisChannel in DateTime format.
"""
function start_end(C::SeisChannel)
    return u2d.(t_win(C.t,C.fs) * 1e-6)
end

"""

  start_end(S::SeisData)

Return start and endtimes of SeisChannel in DateTime format.
"""
function start_end(S::SeisData)
  irr = falses(S.n)
  non_ts = findall(S.fs .== 0)
  irr[non_ts] .= true
  z = zero(Int64)
  start_times = Array{DateTime}(undef,S.n)
  end_times =  Array{DateTime}(undef,S.n)
  for i = 1:S.n
    start_times[i] = u2d(S.t[i][1,2] * μs)
    end_times[i] = u2d(S.t[i][end,2] + (irr[i] ? z : S.t[i][1,2] + sum(S.t[i][2:end,2]) +
        round(Int64, (length(S.x[i])-1)/(μs*S.fs[i]))) * μs)
        # ts data: start time in μs from epoch + sum of time gaps in μs + length of trace in μs
        # non-ts data: time of last sample
  end
  return start_times,end_times
end

"""
    slide(C::SeisChannel, window_length::Real, cc_step::Real)

Generate equal length sliding windows into an array.
"""
function slide(C::SeisChannel, cc_len::Int, cc_step::Int)
  window_samples = Int(cc_len * C.fs)
  su,eu = t_win(C.t,C.fs) * μs
  starts = Array(range(su,stop=eu,step=cc_step))
  ends = starts .+ cc_len .- 1. / C.fs
  ind = findlast(x -> x <= eu,ends)
  starts = starts[1:ind]
  ends = ends[1:ind]

  # fill array with overlapping windows
  A = Array{Float64,2}(undef, window_samples,length(starts))
  s = convert.(Int,round.((hcat(starts,ends) .- su) .* C.fs .+ 1.))
  for ii = 1:length(starts)
    A[:,ii] = C.x[s[ii,1]:s[ii,2]]
  end
  return A,starts,ends
end

"""
    nearest_start_end(C::SeisChannel, cc_len::Int, cc_step::Int)

Return best possible start, end times for data in `C` given the c
"""
function nearest_start_end(C::SeisChannel, cc_len::Int, cc_step::Int)
  su,eu = t_win(C.t,C.fs) * μs
  ideal_start = d2u(DateTime(Date(u2d(su)))) # midnight of same day
  starts = Array(range(ideal_start,stop=eu,step=cc_step))
  ends = starts .+ cc_len .- 1. / C.fs
  return starts[findfirst(x -> x >= su, starts)], ends[findlast(x -> x <= eu,ends)]
end

"""
    nearest_start_end(D::DateTime, cc_len::Int, cc_step::Int)

Return best possible start, end times for given starttime `D`
"""
function nearest_start_end(S::DateTime, E::DateTime, fs::Float64, cc_len::Int, cc_step::Int)
  ideal_start = DateTime(Date(S)) # midnight of same day
  starts = Array(ideal_start:Second(cc_step):endtime)
  ends = starts .+ Second(cc_len) .- Millisecond(convert(Int,1. / fs * 1e3))
  return starts[findfirst(x -> x >= S, starts)], ends[findlast(x -> x <= E,ends)]
end