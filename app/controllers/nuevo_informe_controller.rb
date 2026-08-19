class NuevoInformeController
  def initialize(service = TipoInformeService.new)
    @service = service
  end

  def tipos
    @service.todos.select(&:activo?)
  end
end
