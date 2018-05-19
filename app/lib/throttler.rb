class Throttler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.(env)
  end
end
