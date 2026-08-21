require "yaml"

class TipoInformeService
  def initialize(ruta = "config/tipos_informe.yml")
    @ruta = ruta
  end

  def todos
    datos = YAML.load_file(@ruta)

    datos.fetch("tipos", []).map do |tipo|
      # Mapeamos los campos inyectando la propiedad 'opciones' para los selectores
      campos = tipo.fetch("campos", []).map do |campo|
        CampoInforme.new(
          id: campo.fetch("id"),
          nombre: campo.fetch("nombre"),
          tipo: campo.fetch("tipo"),
          obligatorio: campo.fetch("obligatorio", false),
          opciones: campo.fetch("opciones", []) # <--- CRÍTICO PARA EL SELECTOR Y MULTI-SELECCIÓN
        )
      end

      TipoInforme.new(
        id: tipo.fetch("id"),
        nombre: tipo.fetch("nombre"),
        descripcion: tipo.fetch("descripcion", ""),
        area: tipo.fetch("area", "otros"),
        version: tipo.fetch("version", 1),
        activo: tipo.fetch("activo", true),
        fases: tipo.fetch("fases", []), # <--- INYECTAMOS LAS FASES AL MODELO PRINCIPAL
        campos: campos
      )
    end
  end

  def buscar(id)
    todos.find { |tipo| tipo.id == id }
  end
end