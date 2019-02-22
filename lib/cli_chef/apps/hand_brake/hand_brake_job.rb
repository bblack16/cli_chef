class HandBrakeJob < CLIChef::Job

  attr_int :task_count, :task, default: 1
  attr_float :fps, :average_fps, default: 0

  protected

  def process_line(line, stream = :stdout)
    self.result.body = self.result.body + line
  end
end
