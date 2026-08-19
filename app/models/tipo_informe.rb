class TipoInforme
  attr_reader :id, :nombre, :descripcion, :version, :campos

  def initialize(id:, nombre:, descripcion:, version:, activo:, campos: [])
    @id = id
    @nombre = nombre
    @descripcion = descripcion
    @version = version
    @activo = activo
    @campos = campos
  end

  def activo?
    @activo
  end
end
