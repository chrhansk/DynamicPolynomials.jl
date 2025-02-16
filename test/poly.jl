@testset "Term and Polynomial tests" begin
    @testset "Term" begin
        @polyvar x
        TT = term_type(x)
        TTF = term_type(x, Float64)
        PT = polynomial_type(TT)
        PTF = polynomial_type(TTF)
        @ncpolyvar y
        NCTT = term_type(y)
        #       @test coefficient_type(1x) == Int
        #       @test coefficient_type(1.0x^2) == Float64
        #       @test coefficient_type(Term{true, Int}) == Int
        @test MP.coefficient(zero_term(NCTT)) == 0
        @test MP.coefficient(one(TT)) == 1
        @test typeof(MP.term(1x)) == TT
        @test MP.term(1x) == 1x
        @test typeof(convert(Any, 1x)) == TT
        @test typeof(one(1x)) == TT
        @test typeof(zero_term(1x)) == TT
        @test typeof(zero(1x)) == PT
        @test typeof(one(1.0x)) == TTF
        @test typeof(zero_term(1.0x)) == TTF
        @test typeof(zero(1.0x)) == PTF

        @test typeof(constant_term(1, x)) == TT
        @inferred constant_term(1, x)
        @test typeof(polynomial(1:2, monomials([x], 1:2))) == PT
    end

    @testset "Polynomial" begin
        #@test eltype(polynomial{true, Int}) == Int
        @polyvar x
        TT = term_type(x)
        PT = polynomial_type(x)
        @test_throws ArgumentError PT([1, 2], [x])
        @test_throws ArgumentError PT([1, 2], MonomialVector([x]))
        @test_throws InexactError PT([1.5], [x])
        @test polynomial(1 + x) == 1 + x
        @test typeof(one(1 + x)) == PT
        @test typeof(zero_term(1 + x)) == TT
        @test typeof(zero(1 + x)) == PT
        TTF = term_type(x, Float64)
        PTF = polynomial_type(x, Float64)
        @test typeof(one(1.0 + x)) == PTF
        @test typeof(zero_term(1.0 + x)) == TTF
        @test typeof(zero(1.0 + x)) == PTF

        pf = DynamicPolynomials.Polynomial(i -> 1.0, [x * x, x, x * x])
        @test coefficients(pf) == [1.0, 2.0]
        @test monomials(pf) == monomial_vector([x^2, x])

        p = polynomial([4, 9], [x, x * x])
        p.a == [9, 4]
        p.x[1] == x^2
        p.x[2] == x

        @inferred DynamicPolynomials.Polynomial(i -> float(i), [x, x * x])
        @inferred DynamicPolynomials.Polynomial(i -> float(i), MonomialVector([x * x, x]))
        for p in (
            DynamicPolynomials.Polynomial(i -> float(i), [x, x * x]),
            DynamicPolynomials.Polynomial(i -> float(i), MonomialVector([x * x, x])),
        )
            @test typeof(p) == PTF
            @test p.a == [1.0, 2.0]
            @test p.x == MonomialVector([x^2, x])
        end

        @ncpolyvar ncpolyvar u v
        NCPT = polynomial_type(u)
        @inferred DynamicPolynomials.Polynomial(i -> i, [u, u * u, 1])
        p = DynamicPolynomials.Polynomial(i -> i, [u, u * u, 1])
        @test typeof(p) == NCPT
        @test p.a == [3, 1, 2]
        @test p.x == MonomialVector([u^2, u, 1])

        @test u + v * u + 1 != v * u + u
        @test remove_monomials(u + v * u + 1, [1, u * v]) == v * u + u
        @test remove_monomials(u + u * v + 1, [u * v]) == 1 + u

        @inferred polynomial(2u)
        @inferred polynomial(2.0u, Int)
    end

    @testset "Antiderivative" begin
        @polyvar x y

        p = (x^2 + 4 * y^3)
        @test MP.coefficient_type(p) == Int

        pi = DynamicPolynomials.antidifferentiate(p, y)
        @test pi == (x^2 * y + y^4)

        pi = DynamicPolynomials.antidifferentiate(p, x)
        @test MP.coefficient_type(pi) == Rational{Int}

        p = (1.0 * x^2 + 2.0 * y^2)
        @test MP.coefficient_type(p) == Float64

        pi = DynamicPolynomials.antidifferentiate(p, x)
        @test MP.coefficient_type(pi) == Float64

        p = 2 * y
        pi = DynamicPolynomials.antidifferentiate(p, y)
        @test pi == y^2

        p = x^2
        pi = DynamicPolynomials.antidifferentiate(p, y)
        @test pi == x^2 * y

    end

    @testset "Evaluation" begin
        @polyvar x y
        @test (x^2 + y^3)(2, 3) == 31
        @test (x^2 + y^3)((2, 3)) == 31
        @test (x^2 + y^3)([2, 3]) == 31
        @test (2x^2 * y)(3, 2) == 36
        @test (2x^2 * y)((3, 2)) == 36
        @test (2x^2 * y)([3, 2]) == 36
        @test (2x^2)(3) == 18
        err = ArgumentError(
            "Variable `y` was not assigned a value. Use `subs` to substitute only a subset of the variables.",
        )
        t = 2x^2 * y
        @test_throws err t(x => 1)
        p = 2x^2 + y
        @test_throws err p(x => 1)
        err = ArgumentError(
            "Variable `x` was not assigned a value. Use `subs` to substitute only a subset of the variables.",
        )
        @test_throws err t(y => 1)
        @test_throws err p(y => 1)
    end
end
