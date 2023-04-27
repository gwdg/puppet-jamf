# makes a private context for the variables passed in on the command line
class ErbSandbox
  def initialize(variables)
    variables.each { |name, value| instance_variable_set("@#{name}", value) }
  end

  # Expose private binding() method.
  def public_binding
    binding
  end
end
