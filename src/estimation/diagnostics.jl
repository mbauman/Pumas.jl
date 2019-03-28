"""
  npde(model, subject, param[, rfx], simulations_count)

To calculate the Normalised Prediction Distribution Errors (NPDE).
"""
function npde(m::PuMaSModel,subject::Subject, fixeffs::NamedTuple,nsim)
  yi = subject.observations.dv
  sims = []
  for i in 1:nsim
    vals = simobs(m, subject, fixeffs)
    push!(sims, vals.observed.dv)
  end
  mean_yi = [mean(sims[:][i]) for i in 1:length(sims[1])]
  covm_yi = cov(sims)
  covm_yi = sqrt(inv(covm_yi))
  yi_decorr = (covm_yi)*(yi .- mean_yi)
  phi = []
  for i in 1:nsim
    yi_i = sims[i]
    yi_decorr_i = (covm_yi)*(yi_i .- mean_yi)
    push!(phi,[yi_decorr_i[j]>=yi_decorr[j] ? 0 : 1 for j in 1:length(yi_decorr_i)])
  end
  phi = sum(phi)/nsim
  [quantile(Normal(),phi[i]) for i in 1:length(subject.observations.dv)]
end

"""
  wres(model, subject, param[, rfx])

To calculate the Weighted Residuals (WRES).
"""
function wres(m::PuMaSModel,
              subject::Subject,
              fixeffs::NamedTuple,
              vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FO()))
  y = subject.observations.dv
  nl, dist = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  Ω = Matrix(fixeffs.Ω)
  F = ForwardDiff.jacobian(s -> mean.(conditional_nll_ext(m, subject, fixeffs, (η=s,))[2].dv), vrandeffs)
  V = Symmetric(F*Ω*F' + Diagonal(var.(dist.dv)))
  return cholesky(V).U'\(y .- mean.(dist.dv))
end

"""
  cwres(model, subject, param[, rfx])

To calculate the Conditional Weighted Residuals (CWRES).
"""
function cwres(m::PuMaSModel,
               subject::Subject,
               fixeffs::NamedTuple,
               vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FOCE()))
  y = subject.observations.dv
  nl0, dist0 = conditional_nll_ext(m,subject,fixeffs, (η=zero(vrandeffs),))
  nl , dist  = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  Ω = Matrix(fixeffs.Ω)
  F = ForwardDiff.jacobian(s -> mean.(conditional_nll_ext(m, subject, fixeffs, (η=s,))[2].dv), vrandeffs)
  V = Symmetric(F*Ω*F' + Diagonal(var.(dist0.dv)))
  return cholesky(V).U'\(y .- mean.(dist.dv) .+ F*vrandeffs)
end

"""
  cwresi(model, subject, param[, rfx])

To calculate the Conditional Weighted Residuals with Interaction (CWRESI).
"""

function cwresi(m::PuMaSModel,
                subject::Subject,
                fixeffs::NamedTuple,
                vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FOCEI()))
  y = subject.observations.dv
  nl, dist = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  Ω = Matrix(fixeffs.Ω)
  F = ForwardDiff.jacobian(s -> mean.(conditional_nll_ext(m, subject, fixeffs, (η=s,))[2].dv), vrandeffs)
  V = Symmetric(F*Ω*F' + Diagonal(var.(dist.dv)))
  return cholesky(V).U'\(y .- mean.(dist.dv) .+ F*vrandeffs)
end

"""
  pred(model, subject, param[, rfx])

To calculate the Population Predictions (PRED).
"""
function pred(m::PuMaSModel,subject::Subject, fixeffs::NamedTuple, vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FO()))
  l0, dist0 = conditional_nll_ext(m,subject,fixeffs, (η=zero(vrandeffs),))
  mean_yi = (mean.(dist0.dv))
  mean_yi
end

"""
  cpred(model, subject, param[, rfx])

To calculate the Conditional Population Predictions (CPRED).
"""
function cpred(m::PuMaSModel,subject::Subject, fixeffs::NamedTuple, vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FOCE()))
  l, dist = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  f = Matrix(VectorOfArray([ForwardDiff.gradient(s -> _mean(m, subject, fixeffs, (η=s,), i), vrandeffs) for i in 1:length(subject.observations.dv)]))
  mean_yi = (mean.(dist.dv)) .- vec(f'*vrandeffs)
  mean_yi
end

"""
  cpredi(model, subject, param[, rfx])

To calculate the Conditional Population Predictions with Interaction (CPREDI).
"""
function cpredi(m::PuMaSModel,subject::Subject, fixeffs::NamedTuple, vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FOCEI()))
  l, dist = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  f = Matrix(VectorOfArray([ForwardDiff.gradient(s -> _mean(m, subject, fixeffs, (η=s,), i), vrandeffs) for i in 1:length(subject.observations.dv)]))
  mean_yi = (mean.(dist.dv)) .- vec(f'*vrandeffs)
  mean_yi
end

"""
  epred(model, subject, param[, rfx], simulations_count)

To calculate the Expected Simulation based Population Predictions.
"""
function epred(m::PuMaSModel,subject::Subject, fixeffs::NamedTuple,nsim)
  sims = []
  for i in 1:nsim
    vals = simobs(m, subject, fixeffs)
    push!(sims, vals.observed.dv)
  end
  mean_yi = [mean(sims[:][i]) for i in 1:length(sims[1])]
  mean_yi
end

"""
  iwres(model, subject, param[, rfx])

To calculate the Individual Weighted Residuals (IWRES).
"""
function iwres(m::PuMaSModel,
               subject::Subject,
               fixeffs::NamedTuple,
               vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FO()))
  y = subject.observations.dv
  nl, dist = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  return (y .- mean.(dist.dv)) ./ std.(dist.dv)
end

"""
  icwres(model, subject, param[, rfx])

To calculate the Individual Conditional Weighted Residuals (ICWRES).
"""
function icwres(m::PuMaSModel,
                subject::Subject,
                fixeffs::NamedTuple,
                vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FOCE()))
  y = subject.observations.dv
  nl0, dist0 = conditional_nll_ext(m,subject,fixeffs, (η=zero(vrandeffs),))
  nl , dist  = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  return (y .- mean.(dist.dv)) ./ std.(dist0.dv)
end

"""
  icwresi(model, subject, param[, rfx])

To calculate the Individual Conditional Weighted Residuals with Interaction (ICWRESI).
"""
function icwresi(m::PuMaSModel,
                 subject::Subject,
                 fixeffs::NamedTuple,
                 vrandeffs::AbstractVector=randeffs_estimate(m, subject, fixeffs, FOCEI()))
  y = subject.observations.dv
  l, dist = conditional_nll_ext(m,subject,fixeffs, (η=vrandeffs,))
  return (y .- mean.(dist.dv)) ./ std.(dist.dv)
end

"""
  eiwres(model, subject, param[, rfx], simulations_count)

To calculate the Expected Simulation based Individual Weighted Residuals (EIWRES).
"""
function eiwres(m::PuMaSModel,subject::Subject, fixeffs::NamedTuple, nsim)
  yi = subject.observations.dv
  l, dist = conditional_nll_ext(m,subject,fixeffs)
  mean_yi = (mean.(dist.dv))
  covm_yi = sqrt(inv((Diagonal(var.(dist.dv)))))
  sims_sum = (covm_yi)*(yi .- mean_yi)
  for i in 2:nsim
    l, dist = conditional_nll_ext(m,subject,fixeffs)
    mean_yi = (mean.(dist.dv))
    covm_yi = sqrt(inv((Diagonal(var.(dist.dv)))))
    sims_sum .+= (covm_yi)*(yi .- mean_yi)
  end
  sims_sum./nsim
end

function ηshrinkage(m::PuMaSModel, data::Population, fixeffs::NamedTuple, approx)
  sd_randeffs = std(Matrix(VectorOfArray([randeffs_estimate(m, subject, fixeffs, approx) for subject in data])),dims=2)
  Ω = (fixeffs.Ω)
  shk = 1 .- (sd_randeffs ./ sqrt.(diag(Ω)))
  shk
end

function ϵshrinkage(m::PuMaSModel, data::Population, fixeffs::NamedTuple)
  1 - std(vec([iwres(m, subject, fixeffs) for subject in data]))[1]
end
