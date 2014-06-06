module StripeMock

  def self.get_test_helpers(strategy=nil)
    set_test_strategy(strategy) unless strategy.nil?
    @__test_strat ||= TestStrategies::Mock
    @__test_strat.new
  end

  def self.set_test_strategy(strategy)
    @__test_strat = case strategy
    when :mock then TestStrategies::Mock
    when :live then TestStrategies::Live
    else raise "Invalid test helper stragety: #{stragety.inspect}"
    end
  end
end
