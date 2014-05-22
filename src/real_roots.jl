## Find real zeros of a polynomial
## This follows simplest algorithm outlined here: http://en.wikipedia.org/wiki/Vincent's_theorem
## Basically there are these steps:
## * we make the polynomial square free by finding psf = gcd(p, p') using gcd code from multroot
## * we consider the positive roots of the polynomial x->psf(x) and x->psf(-x)
## * for each an upper bound on the maximal real root is found using the Cauchy method.
##   other tighter bounds are possible, but this is easier to implement
## * we then do a bisection method on [0, ub]. The number of real roots in [a,b] is bounded above
##   by descarte's sign change rule on a modified polynomial. It this is 0, there is no root, 1 there is one
##   root we find using fzero, more than 1, then we bisect interval. 
##
## Drawbacks: the finding of a gcd to make p square free is problematic:
## * It can fail for large polynomials (wilkinson)
## * It can fail for nearby roots. (x-1+delta)*(x-1-delta) type things

## Some utilities

  
function descartes_bound(p::Poly)
    ps = p.a
    b = map(sign, ps)
    sum(map(*, b[1:end-1], b[2:end]) .< 0)        
end

## could do this with polynomial type alone with
function ab_test(p::Poly, a, b)
    @assert a < b

    as = reverse(p.a)
    n = length(as) - 1
    x = poly([0.0], p.var)
    q = sum([as[i]*(a+b*x)^(i-1)*(1+x)^(n+1-i) for i in 1:(n+1)])
    descartes_bound(q)
end
      

function upperbound(p::Poly)
    as = reverse(p.a)             # a0, a1, ..., an
    as = as/sign(as[end])
    n = length(as) - 1
    ps = map(sign, as)         # signs
    ks = ps .< 0               # negative coefficients
    lamda = sum(ks)
    
    lamda > 0 || return(0) # nothing to be found if no negative coefficients

    mx = 0.0
    for k in 1:n
        if as[n+1-k] < 0
            mx = max(mx, (-lamda * as[n+1-k]/ as[n+1])^(1/k))
        end
    end
    mx + 1e-2 * rand()          # make slightly large
end




## positive roots are all in (0, ub)
## p is square-free
function VAG(p::Poly, a, b) 
    if a > b
        a,b = b, a
    end

    rts = Float64[]
    nr = ab_test(p, a, b)

    if nr == 1
        push!(rts, fzero(p, [a, b]))
    elseif nr > 1
        gamma = (a + b)/2
        tmp = Polynomial.polyval(p, gamma)
        if Polynomial.polyval(p, gamma) == 0.0
            append!(rts, [gamma])
        end
        if a< gamma < b
            append!(rts, VAG(p, a, gamma))
            append!(rts, VAG(p, gamma, b))
        end
    end
    
    return(rts)
end
    


## find values on left and right of 0
function VAG(p::Poly; tol::Real=4*eps())
    rts = Float64[]

    if abs(Polynomial.polyval(p, 0.0)) <= tol
        push!(rts, 0.0)
    end

    ## positive roots
    append!(rts, VAG(p, tol, upperbound(p)))
    ## negative roots. Need p->-p
    as = reverse(p.a)
    as[2:2:length(as)] = -as[2:2:length(as)]
    q = Poly(as)
    append!(rts, -VAG(q, tol, upperbound(q)))
end


## find real_roots of a polynomial
function real_roots(p::Poly)
    try
        ## need square free
        n, u, v, w = Roots.gcd_degree(p)
        VAG(v)
    catch e
        ## assume that polynomial is square free!
        VAG(p)
    end
end    
