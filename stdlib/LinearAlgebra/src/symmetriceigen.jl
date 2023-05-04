# This file is a part of Julia. License is MIT: https://julialang.org/license

# preserve HermOrSym wrapper
eigencopy_oftype(A::Hermitian, S) = Hermitian(copy_similar(A, S), sym_uplo(A.uplo))
eigencopy_oftype(A::Symmetric, S) = Symmetric(copy_similar(A, S), sym_uplo(A.uplo))

default_eigen_alg(A) = DivideAndConquer()

# Eigensolvers for symmetric and Hermitian matrices
function eigen!(A::RealHermSymComplexHerm{<:BlasReal,<:StridedMatrix}, alg::Algorithm = default_eigen_alg(A); sortby::Union{Function,Nothing}=nothing)
    if alg === DivideAndConquer()
        Eigen(sorteig!(LAPACK.syevd!('V', A.uplo, A.data)..., sortby)...)
    elseif alg === QRIteration()
        Eigen(sorteig!(LAPACK.syev!('V', A.uplo, A.data)..., sortby)...)
    elseif alg === RobustRepresentations()
        Eigen(sorteig!(LAPACK.syevr!('V', 'A', A.uplo, A.data, 0.0, 0.0, 0, 0, -1.0)..., sortby)...)
    else
        throw(ArgumentError("Unsupported value for `alg` keyword."))
    end
end

"""
    eigen(A::Union{Hermitian, Symmetric}, alg::Algorithm = default_eigen_alg(A)) -> Eigen

Compute the eigenvalue decomposition of `A`, returning an [`Eigen`](@ref) factorization object `F`
which contains the eigenvalues in `F.values` and the eigenvectors in the columns of the
matrix `F.vectors`. (The `k`th eigenvector can be obtained from the slice `F.vectors[:, k]`.)

Iterating the decomposition produces the components `F.values` and `F.vectors`.

`alg` specifies which algorithm and LAPACK method to use for eigenvalue decomposition:
- `alg = DivideAndConquer()` (default): Calls `LAPACK.syevd`.
- `alg = QRIteration()`: Calls `LAPACK.syev`.
- `alg = RobustRepresentations()`: Multiple relatively robust representations method, Calls `LAPACK.syevr!`.

See James W. Demmel et al, SIAM J. Sci. Comput. 30, 3, 1508 (2008) for
a comparison of the accuracy and performance of different algorithms.

The default `alg` used may change in the future.

!!! compat "Julia 1.10"
    The `alg` keyword argument requires Julia 1.10 or later.

The following functions are available for `Eigen` objects: [`inv`](@ref), [`det`](@ref), and [`isposdef`](@ref).
"""
function eigen(A::RealHermSymComplexHerm, alg::Algorithm = default_eigen_alg(A); sortby::Union{Function,Nothing}=nothing)
    S = eigtype(eltype(A))
    eigen!(eigencopy_oftype(A, S), alg; sortby)
end


eigen!(A::RealHermSymComplexHerm{<:BlasReal,<:StridedMatrix}, irange::UnitRange) =
    Eigen(LAPACK.syevr!('V', 'I', A.uplo, A.data, 0.0, 0.0, irange.start, irange.stop, -1.0)...)

"""
    eigen(A::Union{SymTridiagonal, Hermitian, Symmetric}, irange::UnitRange) -> Eigen

Compute the eigenvalue decomposition of `A`, returning an [`Eigen`](@ref) factorization object `F`
which contains the eigenvalues in `F.values` and the eigenvectors in the columns of the
matrix `F.vectors`. (The `k`th eigenvector can be obtained from the slice `F.vectors[:, k]`.)

Iterating the decomposition produces the components `F.values` and `F.vectors`.

The following functions are available for `Eigen` objects: [`inv`](@ref), [`det`](@ref), and [`isposdef`](@ref).

The [`UnitRange`](@ref) `irange` specifies indices of the sorted eigenvalues to search for.

!!! note
    If `irange` is not `1:n`, where `n` is the dimension of `A`, then the returned factorization
    will be a *truncated* factorization.
"""
function eigen(A::RealHermSymComplexHerm, irange::UnitRange)
    S = eigtype(eltype(A))
    eigen!(eigencopy_oftype(A, S), irange)
end

eigen!(A::RealHermSymComplexHerm{T,<:StridedMatrix}, vl::Real, vh::Real) where {T<:BlasReal} =
    Eigen(LAPACK.syevr!('V', 'V', A.uplo, A.data, convert(T, vl), convert(T, vh), 0, 0, -1.0)...)

"""
    eigen(A::Union{SymTridiagonal, Hermitian, Symmetric}, vl::Real, vu::Real) -> Eigen

Compute the eigenvalue decomposition of `A`, returning an [`Eigen`](@ref) factorization object `F`
which contains the eigenvalues in `F.values` and the eigenvectors in the columns of the
matrix `F.vectors`. (The `k`th eigenvector can be obtained from the slice `F.vectors[:, k]`.)

Iterating the decomposition produces the components `F.values` and `F.vectors`.

The following functions are available for `Eigen` objects: [`inv`](@ref), [`det`](@ref), and [`isposdef`](@ref).

`vl` is the lower bound of the window of eigenvalues to search for, and `vu` is the upper bound.

!!! note
    If [`vl`, `vu`] does not contain all eigenvalues of `A`, then the returned factorization
    will be a *truncated* factorization.
"""
function eigen(A::RealHermSymComplexHerm, vl::Real, vh::Real)
    S = eigtype(eltype(A))
    eigen!(eigencopy_oftype(A, S), vl, vh)
end


function eigvals!(A::RealHermSymComplexHerm{<:BlasReal,<:StridedMatrix}, alg::Algorithm = default_eigen_alg(A); sortby::Union{Function,Nothing}=nothing)
    vals::Vector{real(eltype(A))} = if alg === DivideAndConquer()
        LAPACK.syevd!('N', A.uplo, A.data)
    elseif alg === QRIteration()
        LAPACK.syev!('N', A.uplo, A.data)
    elseif alg === RobustRepresentations()
        LAPACK.syevr!('N', 'A', A.uplo, A.data, 0.0, 0.0, 0, 0, -1.0)[1]
    else
        throw(ArgumentError("Unsupported value for `alg` keyword."))
    end
    !isnothing(sortby) && sort!(vals, by=sortby)
    return vals
end

"""
    eigvals(A::Union{Hermitian, Symmetric}, alg::Algorithm = default_eigen_alg(A))) -> values

Return the eigenvalues of `A`.

`alg` specifies which algorithm and LAPACK method to use for eigenvalue decomposition:
- `alg = DivideAndConquer()` (default): Calls `LAPACK.syevd`.
- `alg = QRIteration()`: Calls `LAPACK.syev`.
- `alg = RobustRepresentations()`: Multiple relatively robust representations method, Calls `LAPACK.syevr!`.

See James W. Demmel et al, SIAM J. Sci. Comput. 30, 3, 1508 (2008) for
a comparison of the accuracy and performance of different methods.

The default `alg` used may change in the future.
"""
function eigvals(A::RealHermSymComplexHerm, alg::Algorithm = default_eigen_alg(A); sortby::Union{Function,Nothing}=nothing)
    S = eigtype(eltype(A))
    eigvals!(eigencopy_oftype(A, S), alg; sortby)
end


"""
    eigvals!(A::Union{SymTridiagonal, Hermitian, Symmetric}, irange::UnitRange) -> values

Same as [`eigvals`](@ref), but saves space by overwriting the input `A`, instead of creating a copy.
`irange` is a range of eigenvalue *indices* to search for - for instance, the 2nd to 8th eigenvalues.
"""
eigvals!(A::RealHermSymComplexHerm{<:BlasReal,<:StridedMatrix}, irange::UnitRange) =
    LAPACK.syevr!('N', 'I', A.uplo, A.data, 0.0, 0.0, irange.start, irange.stop, -1.0)[1]

"""
    eigvals(A::Union{SymTridiagonal, Hermitian, Symmetric}, irange::UnitRange) -> values

Return the eigenvalues of `A`. It is possible to calculate only a subset of the
eigenvalues by specifying a [`UnitRange`](@ref) `irange` covering indices of the sorted eigenvalues,
e.g. the 2nd to 8th eigenvalues.

# Examples
```jldoctest
julia> A = SymTridiagonal([1.; 2.; 1.], [2.; 3.])
3×3 SymTridiagonal{Float64, Vector{Float64}}:
 1.0  2.0   ⋅
 2.0  2.0  3.0
  ⋅   3.0  1.0

julia> eigvals(A, 2:2)
1-element Vector{Float64}:
 0.9999999999999996

julia> eigvals(A)
3-element Vector{Float64}:
 -2.1400549446402604
  1.0000000000000002
  5.140054944640259
```
"""
function eigvals(A::RealHermSymComplexHerm, irange::UnitRange)
    S = eigtype(eltype(A))
    eigvals!(eigencopy_oftype(A, S), irange)
end

"""
    eigvals!(A::Union{SymTridiagonal, Hermitian, Symmetric}, vl::Real, vu::Real) -> values

Same as [`eigvals`](@ref), but saves space by overwriting the input `A`, instead of creating a copy.
`vl` is the lower bound of the interval to search for eigenvalues, and `vu` is the upper bound.
"""
eigvals!(A::RealHermSymComplexHerm{T,<:StridedMatrix}, vl::Real, vh::Real) where {T<:BlasReal} =
    LAPACK.syevr!('N', 'V', A.uplo, A.data, convert(T, vl), convert(T, vh), 0, 0, -1.0)[1]

"""
    eigvals(A::Union{SymTridiagonal, Hermitian, Symmetric}, vl::Real, vu::Real) -> values

Return the eigenvalues of `A`. It is possible to calculate only a subset of the eigenvalues
by specifying a pair `vl` and `vu` for the lower and upper boundaries of the eigenvalues.

# Examples
```jldoctest
julia> A = SymTridiagonal([1.; 2.; 1.], [2.; 3.])
3×3 SymTridiagonal{Float64, Vector{Float64}}:
 1.0  2.0   ⋅
 2.0  2.0  3.0
  ⋅   3.0  1.0

julia> eigvals(A, -1, 2)
1-element Vector{Float64}:
 1.0000000000000009

julia> eigvals(A)
3-element Vector{Float64}:
 -2.1400549446402604
  1.0000000000000002
  5.140054944640259
```
"""
function eigvals(A::RealHermSymComplexHerm, vl::Real, vh::Real)
    S = eigtype(eltype(A))
    eigvals!(eigencopy_oftype(A, S), vl, vh)
end

eigmax(A::RealHermSymComplexHerm{<:Real}) = eigvals(A, size(A, 1):size(A, 1))[1]
eigmin(A::RealHermSymComplexHerm{<:Real}) = eigvals(A, 1:1)[1]

function eigen!(A::HermOrSym{T,S}, B::HermOrSym{T,S}; sortby::Union{Function,Nothing}=nothing) where {T<:BlasReal,S<:StridedMatrix}
    vals, vecs, _ = LAPACK.sygvd!(1, 'V', A.uplo, A.data, B.uplo == A.uplo ? B.data : copy(B.data'))
    GeneralizedEigen(sorteig!(vals, vecs, sortby)...)
end
function eigen!(A::Hermitian{T,S}, B::Hermitian{T,S}; sortby::Union{Function,Nothing}=nothing) where {T<:BlasComplex,S<:StridedMatrix}
    vals, vecs, _ = LAPACK.sygvd!(1, 'V', A.uplo, A.data, B.uplo == A.uplo ? B.data : copy(B.data'))
    GeneralizedEigen(sorteig!(vals, vecs, sortby)...)
end
function eigen!(A::RealHermSymComplexHerm{T,<:StridedMatrix}, B::AbstractMatrix{T}; sortby::Union{Function,Nothing}=nothing) where {T<:Number}
    return _choleigen!(A, B, sortby)
end
function eigen!(A::StridedMatrix{T}, B::Union{RealHermSymComplexHerm{T},Diagonal{T}}; sortby::Union{Function,Nothing}=nothing) where {T<:Number}
    return _choleigen!(A, B, sortby)
end
function _choleigen!(A, B, sortby)
    U = cholesky(B).U
    vals, w = eigen!(UtiAUi!(A, U))
    vecs = U \ w
    GeneralizedEigen(sorteig!(vals, vecs, sortby)...)
end

# Perform U' \ A / U in-place, where U::Union{UpperTriangular,Diagonal}
UtiAUi!(A::StridedMatrix, U) = _UtiAUi!(A, U)
UtiAUi!(A::Symmetric, U) = Symmetric(_UtiAUi!(copytri!(parent(A), A.uplo), U), sym_uplo(A.uplo))
UtiAUi!(A::Hermitian, U) = Hermitian(_UtiAUi!(copytri!(parent(A), A.uplo, true), U), sym_uplo(A.uplo))

_UtiAUi!(A, U) = rdiv!(ldiv!(U', A), U)

function eigvals!(A::HermOrSym{T,S}, B::HermOrSym{T,S}; sortby::Union{Function,Nothing}=nothing) where {T<:BlasReal,S<:StridedMatrix}
    vals = LAPACK.sygvd!(1, 'N', A.uplo, A.data, B.uplo == A.uplo ? B.data : copy(B.data'))[1]
    isnothing(sortby) || sort!(vals, by=sortby)
    return vals
end
function eigvals!(A::Hermitian{T,S}, B::Hermitian{T,S}; sortby::Union{Function,Nothing}=nothing) where {T<:BlasComplex,S<:StridedMatrix}
    vals = LAPACK.sygvd!(1, 'N', A.uplo, A.data, B.uplo == A.uplo ? B.data : copy(B.data'))[1]
    isnothing(sortby) || sort!(vals, by=sortby)
    return vals
end
eigvecs(A::HermOrSym) = eigvecs(eigen(A))
