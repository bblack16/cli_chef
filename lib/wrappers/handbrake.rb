class Handbrake < CLIChef::Cookbook

  def initialize path: nil
    self.init 'Handbrake', 'HandBrake is a tool for converting video from nearly any format to a selection of modern, widely supported codecs.', path
  end

  def help
    run(help:true)[:response]
  end
  
  def reencode input, output, **args
    run({input: input, output: output}.merge(args))[:response]
  end

  protected

    def setup_exit_codes
      @exit_codes = {
        0 => 'Clean exit',
        1 => 'HandBrake encountered a crash condition it could not recover from',
      }
    end

    def setup_default_locations
      @default_locations = ['C:/Program Files/Handbrake/HandbrakeCLI.exe', 'C:/Program Files(x86)/Handbrake/HandbrakeCLI.exe', 'C:/Handbrake/HandbrakeCLI.exe']
    end

    def setup_recipes
      # None so far...
    end

    def setup_ingredients
      @cabinet.from_tsv File.read "#{File.dirname __dir__}/wrappers/handbrake.tsv"
    end

end
