require "prawn"
require "prawn/table"
require "fileutils"
require "time"

class GeneradorPdfService
  def initialize(tipo, datos)
    @tipo = tipo
    @datos = datos
  end

  def generar(ruta)
    FileUtils.mkdir_p(File.dirname(ruta))

    Prawn::Document.generate(ruta, page_size: "A4") do |pdf|
      generar_cabecera(pdf)
      generar_datos(pdf)
      generar_pie(pdf)
    end

    ruta
  end

  private

  def generar_cabecera(pdf)
    pdf.text @tipo.nombre,
             size: 22,
             style: :bold

    pdf.move_down 8

    pdf.text @tipo.descripcion,
             size: 11

    pdf.move_down 15

    pdf.stroke_horizontal_rule

    pdf.move_down 15

    pdf.text "Tipo: #{@tipo.id}"
    pdf.text "Versión: #{@tipo.version}"
    pdf.text "Fecha de generación: #{Time.now.strftime("%d/%m/%Y %H:%M")}"

    pdf.move_down 20
  end

  def generar_datos(pdf)
    filas = []

    @tipo.campos.each do |campo|
      valor = @datos[campo.id]

      filas << [
        campo.nombre,
        formatear_valor(valor)
      ]
    end

    pdf.table(
      filas,
      width: pdf.bounds.width,
      cell_style: {
        padding: 8,
        borders: [:bottom]
      }
    ) do
      columns(0).font_style = :bold
    end
  end

  def generar_pie(pdf)
    pdf.move_down 30

    pdf.stroke_horizontal_rule

    pdf.move_down 10

    pdf.text(
      "Generador de Informes IML",
      size: 9,
      align: :center
    )
  end

  def formatear_valor(valor)
    return "" if valor.nil?

    case valor
    when TrueClass
      "Sí"
    when FalseClass
      "No"
    else
      valor.to_s
    end
  end
end
