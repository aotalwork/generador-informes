class CampoInforme
  attr_reader :id, :nombre, :tipo, :obligatorio, :opciones

  def initialize(id:, nombre:, tipo:, obligatorio: false, opciones: [])
    @id = id
    @nombre = nombre
    @tipo = tipo
    @obligatorio = obligatorio
    @opciones = opciones
  end

  def obligatorio?
    @obligatorio
  end
end
