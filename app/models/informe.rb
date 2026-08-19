class Informe
  attr_accessor :id,
                :tipo,
                :tipo_version,
                :estado,
                :datos,
                :fecha_creacion,
                :fecha_modificacion

  ESTADOS = %w[BORRADOR GENERADO FIRMADO].freeze

  def initialize(
    id: nil,
    tipo:,
    tipo_version: 1,
    estado: "BORRADOR",
    datos: {},
    fecha_creacion: Time.now,
    fecha_modificacion: Time.now
  )
    @id = id
    @tipo = tipo
    @tipo_version = tipo_version
    @estado = estado
    @datos = datos
    @fecha_creacion = fecha_creacion
    @fecha_modificacion = fecha_modificacion
  end

  def borrador?
    estado == "BORRADOR"
  end

  def generado?
    estado == "GENERADO"
  end

  def firmado?
    estado == "FIRMADO"
  end
end
