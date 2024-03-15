@testset "QBasedPolicy" begin

    @testset "constructor" begin
        q_approx = TabularQApproximator(n_state = 5, n_action = 10, opt = InvDecay(0.5))
        explorer = EpsilonGreedyExplorer(0.1)
        p = QBasedPolicy(q_approx, explorer)
        @test p.learner == q_approx
        @test p.explorer == explorer
    end

    @testset "plan!" begin
        @testset "plan! without player argument" begin
            env = TicTacToeEnv()
            q_approx = TabularQApproximator(n_state = 5, n_action = length(action_space(env)), opt = InvDecay(0.5))
            explorer = EpsilonGreedyExplorer(0.1)
            policy = QBasedPolicy(q_approx, explorer)
            @test 1 <= RLBase.plan!(policy, env) <= 9
        end

        @testset "plan! with player argument" begin
            env = TicTacToeEnv()
            q_approx = TabularQApproximator(n_state = 5, n_action = length(action_space(env)), opt = InvDecay(0.5))
            explorer = EpsilonGreedyExplorer(0.1)
            policy = QBasedPolicy(q_approx, explorer)
            player = :player1
            @test 1 <= RLBase.plan!(policy, env) <= 9
        end
    end

    # Test prob function
    @testset "prob" begin
        env = TicTacToeEnv()
        q_approx = TabularQApproximator(n_state = 5, n_action = length(action_space(env)), opt = InvDecay(0.5))
        explorer = EpsilonGreedyExplorer(0.1)
        policy = QBasedPolicy(q_approx, explorer)
        # prob = RLBase.prob(p, env)
        # Add assertions here
    end

    # Test optimise! function
    @testset "optimise!" begin
        env = TicTacToeEnv()
        q_approx = TabularQApproximator(n_state = 5, n_action = length(action_space(env)), opt = InvDecay(0.5))
        explorer = EpsilonGreedyExplorer(0.1)
        policy = QBasedPolicy(q_approx, explorer)
        s = PreActStage()
        trajectory = Trajectory(
            CircularArraySARTSTraces(; capacity = 1),
            BatchSampler(1),
            InsertSampleRatioController(n_inserted = -1),
        )
        RLBase.optimise!(policy, s, trajectory)
        # Add assertions here
    end
end
