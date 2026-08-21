class TipoInforme
  attr_reader :id, :nombre, :descripcion, :area, :version, :fases, :campos

  def initialize(
    id:,
    nombre:,
    descripcion:,
    area: "otros",
    version:,
    activo:,
    fases: [], # <--- AÑADIDO: Recibe las fases del YAML
    campos: []
  )
    @id = id
    @nombre = nombre
    @descripcion = descripcion
    @area = area
    @version = version
    @activo = activo
    @fases = fases   # <--- AÑADIDO: Inicializa el atributo de fases
    @campos = campos
  end

  def activo?
    @activo
  end
end
