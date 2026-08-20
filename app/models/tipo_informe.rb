class TipoInforme
  attr_reader :id, :nombre, :descripcion, :area, :version, :campos

  def initialize(
    id:,
    nombre:,
    descripcion:,
    area: "otros",
    version:,
    activo:,
    campos: []
  )
    @id = id
    @nombre = nombre
    @descripcion = descripcion
    @area = area
    @version = version
    @activo = activo
    @campos = campos
  end

  def activo?
    @activo
  end
end