using Test
using Flux
using ReinforcementLearningCore

@testset "TargetNetwork Tests" begin
    @testset "Creation" begin
        model = Chain(Dense(10, 5, relu), Dense(5, 2))
        optimiser = Adam()
        if ((@isdefined CUDA) && CUDA.functional()) || ((@isdefined Metal) && Metal.functional())
            @test_throws "AssertionError: `FluxModelApproximator` model is not on GPU." TargetNetwork(FluxModelApproximator(model, optimiser), use_gpu=true)
        end
        @test TargetNetwork(FluxModelApproximator(model=model, optimiser=optimiser, use_gpu=true), use_gpu=true) isa TargetNetwork
        @test TargetNetwork(FluxModelApproximator(model, optimiser, use_gpu=true), use_gpu=true) isa TargetNetwork

        approx = FluxModelApproximator(model, optimiser, use_gpu=false)
        target_network = TargetNetwork(approx, use_gpu=false)

        
        @test target_network isa TargetNetwork
        @test typeof(target_network.network) == typeof(approx)
        @test target_network.target isa Flux.Chain
        @test target_network.sync_freq == 1
        @test target_network.ρ == 0.0
        @test target_network.n_optimise == 0    
    end

    @testset "Forward" begin
        model = Chain(Dense(10, 5, relu), Dense(5, 2))
        target_network = TargetNetwork(FluxModelApproximator(model, Adam()))
    
        input = rand(Float32, 10)
        output = RLCore.forward(target_network, input)
    
        @test typeof(output) == Array{Float32,1}
        @test length(output) == 2    
    end

    @testset "Optimise" begin
        optimiser = Adam()
        model = Chain(Dense(10, 5, relu), Dense(5, 2))
        approximator = FluxModelApproximator(model, optimiser)
        target_network = TargetNetwork(approximator)
        input = rand(Float32, 10)    
        grad = Flux.Zygote.gradient(target_network) do model
            sum(RLCore.forward(model, input))
        end
    
        @test target_network.network.model.layers[2].bias == [0, 0]
        RLCore.optimise!(target_network, grad[1])

        @test target_network.network.model.layers[2].bias != [0, 0]

    end

    @testset "Sync" begin
        optimiser = Adam()
        model = FluxModelApproximator(Chain(Dense(10, 5, relu), Dense(5, 2)), optimiser)
        target_network = TargetNetwork(model, sync_freq=2, ρ=0.5)
    
        input = rand(Float32, 10)
        grad = Flux.Zygote.gradient(target_network) do model
            sum(RLCore.forward(model, input))
        end

        optimise!(target_network, grad[1])
        @test target_network.n_optimise == 1
    
        optimise!(target_network, grad[1])
        @test target_network.n_optimise == 0
    
    end
end

@testset "TargetNetwork" begin 
    m = Chain(Dense(4,1))
    app = FluxModelApproximator(model = m, optimiser = Flux.Adam(), use_gpu=true)
    tn = TargetNetwork(app, sync_freq = 3, use_gpu=true)
    @test typeof(model(tn)) == typeof(target(tn))
    p1 = Flux.destructure(model(tn))[1]
    pt1 = Flux.destructure(target(tn))[1]
    @test p1 == pt1
    input = gpu(ones(Float32, 4))
    grad = Flux.Zygote.gradient(tn) do model
        sum(RLCore.forward(model, input))
    end

    grad_model = grad[1]
    
    RLCore.optimise!(tn, grad_model)
    @test p1 != Flux.destructure(model(tn))[1]
    @test p1 == Flux.destructure(target(tn))[1]
    RLCore.optimise!(tn, grad_model)
    @test p1 != Flux.destructure(model(tn))[1]
    @test p1 == Flux.destructure(target(tn))[1]
    RLCore.optimise!(tn, grad_model)
    @test Flux.destructure(target(tn))[1] == Flux.destructure(model(tn))[1]
    @test p1 != Flux.destructure(target(tn))[1]
    p2 = Flux.destructure(model(tn))[1]
    RLCore.optimise!(tn, grad_model)
    @test p2 != Flux.destructure(model(tn))[1]
    @test p2 == Flux.destructure(target(tn))[1]
end
