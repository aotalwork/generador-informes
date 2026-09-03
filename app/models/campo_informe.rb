class CampoInforme
  attr_reader :id, :nombre, :tipo, :obligatorio, :opciones, :frases

  def initialize(
    id:,
    nombre:,
    tipo:,
    obligatorio: false,
    opciones: [],
    frases: {}
  )
    @id = id
    @nombre = nombre
    @tipo = tipo
    @obligatorio = obligatorio
    @opciones = opciones
    @frases = frases
  end

  def obligatorio?
    @obligatorio
  end
end