class CampoInforme
  attr_reader :id, :nombre, :tipo, :obligatorio

  def initialize(id:, nombre:, tipo:, obligatorio: false)
    @id = id
    @nombre = nombre
    @tipo = tipo
    @obligatorio = obligatorio
  end

  def obligatorio?
    @obligatorio
  end
end
